package com.mr.ac_project_app.view.share

import android.app.Application
import android.content.ContentValues
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.text.TextUtils
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.MutableLiveData
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.jsoup.Jsoup

class ShareViewModel(application: Application) : AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper
    var savedLink = MutableLiveData("")
    val linkSeq = MutableLiveData(-1L)
    var imageLink = MutableLiveData<String>()
    private var isLinkSaved = MutableLiveData(false)

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun saveLink(link: String) {
        if (isLinkSaved.value!! || TextUtils.isEmpty(link)) {
            return
        }
        savedLink.postValue(link)
        CoroutineScope(Dispatchers.IO).launch {
            val linkOpenGraph = HashMap<String, String>()
            val document = Jsoup.connect(link).get()
            val elements = document.select("meta[property^=og:]")
            elements?.let {
                it.forEach { item ->
                    when (item.attr("property")) {
                        "og:url" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("url", content)
                            }
                        }
                        "og:site_name" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("siteName", content)
                            }
                        }
                        "og:title" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("title", content)
                            }
                        }
                        "og:description" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("description", content)
                            }
                        }
                        "og:image" -> {
                            linkOpenGraph["image"] = item.attr("content")
                        }
                    }
                }
            }
            imageLink.postValue(linkOpenGraph["image"] ?: "")
            linkSeq.postValue(saveLinkWithoutFolder(link, linkOpenGraph["title"] ?: ""))
            isLinkSaved.postValue(true)
        }
    }

    private fun saveLinkWithoutFolder(savedLink: String, title: String): Long {
        val db = dbHelper.writableDatabase
        val values = ContentValues().apply {
            put(ShareContract.LinkTempEntry.link, savedLink)
            put(ShareContract.LinkTempEntry.imageLink, imageLink.value)
            put(ShareContract.LinkTempEntry.title, title)
        }
        val linkSeq = db.insert(ShareContract.LinkTempEntry.table, null, values)
        db.close()
        return linkSeq
    }

    fun saveLinkWithFolder(folder: FolderModel, linkSeq: Long?) {
        val db = dbHelper.writableDatabase
        val values = ContentValues().apply {
            put(ShareContract.LinkTempEntry.folderSeq, folder.seq)
        }
        db.update(
            ShareContract.LinkTempEntry.table,
            values,
            "${ShareContract.LinkTempEntry.seq} = ?",
            arrayOf("$linkSeq")
        )
        db.close()
    }

    fun getFoldersFromDB(): MutableList<FolderModel> {
        val db = dbHelper.readableDatabase
        val folderTempColumns =
            arrayOf(
                ShareContract.FolderTempEntry.seq,
                ShareContract.FolderTempEntry.folderName,
                ShareContract.FolderTempEntry.visible
            )
        val folderColumns =
            arrayOf(
                ShareContract.FolderEntry.seq,
                ShareContract.FolderEntry.folderName,
                ShareContract.FolderEntry.visible
            )
        val folderTempCursor =
            db.query(
                ShareContract.FolderTempEntry.table,
                folderTempColumns,
                null,
                null,
                null,
                null,
                null
            )
        val folderCursor =
            db.query(ShareContract.FolderEntry.table, folderColumns, null, null, null, null, null)

        val linkColumns = arrayOf(ShareContract.LinkTempEntry.imageLink)

        val folders = mutableListOf<FolderModel>()
        folders.addAll(
            getFolderImage(
                folderTempCursor,
                db,
                ShareContract.FolderTempEntry.seq,
                ShareContract.FolderTempEntry.folderName,
                ShareContract.FolderTempEntry.visible,
                linkColumns
            )
        )
        folders.addAll(
            getFolderImage(
                folderCursor,
                db,
                ShareContract.FolderEntry.seq,
                ShareContract.FolderEntry.folderName,
                ShareContract.FolderEntry.visible,
                linkColumns
            )
        )
        db.close()
        return folders
    }

    private fun getFolderImage(
        folderCursor: Cursor,
        db: SQLiteDatabase,
        folderSeq: String,
        folderNameColumn: String,
        visibleColumn: String,
        linkColumns: Array<String>,
    ): MutableList<FolderModel> {
        val folders = mutableListOf<FolderModel>()
        with(folderCursor) {
            while (moveToNext()) {
                val seq = getLong(getColumnIndexOrThrow(folderSeq))
                val folderName = getString(getColumnIndexOrThrow(folderNameColumn))
                val visible = getInt(getColumnIndexOrThrow(visibleColumn)) == 1

                val linkTempCursor =
                    getRecentImageUrl(
                        db,
                        ShareContract.LinkTempEntry.table,
                        linkColumns,
                        ShareContract.LinkTempEntry.folderSeq,
                        ShareContract.LinkTempEntry.seq,
                        seq
                    )
                val linkCursor =
                    getRecentImageUrl(
                        db,
                        ShareContract.LinkEntry.table,
                        linkColumns,
                        ShareContract.LinkEntry.folderSeq,
                        ShareContract.LinkEntry.seq,
                        seq
                    )

                val imageLinks = mutableListOf<String>()
                imageLinks.addAll(
                    addImageLinks(
                        linkTempCursor,
                        ShareContract.LinkTempEntry.imageLink
                    )
                )
                imageLinks.addAll(addImageLinks(linkCursor, ShareContract.LinkEntry.imageLink))

                if (imageLinks.size > 0) {
                    folders.add(
                        FolderModel(
                            FolderType.One,
                            imageLinks[0],
                            folderName,
                            visible,
                            seq
                        )
                    )
                } else {
                    folders.add(
                        FolderModel(
                            FolderType.None,
                            null,
                            folderName,
                            visible,
                            seq
                        )
                    )
                }
            }
        }
        folderCursor.close()
        return folders
    }


    private fun addImageLinks(
        linkCursor: Cursor,
        imageLink: String
    ): MutableList<String> {
        val imageLinks = mutableListOf<String>()
        with(linkCursor) {
            while (moveToNext()) {
                imageLinks.add(getString(getColumnIndexOrThrow(imageLink)))
            }
        }
        linkCursor.close()
        return imageLinks
    }

    private fun getRecentImageUrl(
        db: SQLiteDatabase,
        table: String,
        linkColumns: Array<String>,
        folderSeq: String,
        linkSeq: String,
        seq: Long
    ) = db.query(
        table,
        linkColumns,
        "$folderSeq = ?",
        arrayOf("$seq"),
        null,
        null,
        "$linkSeq DESC",
        "1"
    )
}