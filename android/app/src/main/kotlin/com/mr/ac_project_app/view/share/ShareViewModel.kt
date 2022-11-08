package com.mr.ac_project_app.view.share

import android.app.Application
import android.content.ContentValues
import android.database.Cursor
import android.text.TextUtils
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.MutableLiveData
import com.mr.ac_project_app.LinkPoolApp
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.data.SharedPrefHelper
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import com.mr.ac_project_app.utils.convert
import com.mr.ac_project_app.utils.getCurrentDateTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.jsoup.Jsoup

class ShareViewModel(application: Application) : AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper
    var savedLink = MutableLiveData("")
    var imageLink = MutableLiveData<String>()
    private var title = MutableLiveData<String>()
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
                            var imageUrl = item.attr("content")
                            if (!imageUrl.contains("http")) {
                                imageUrl = if (link.contains("https")) {
                                    "https:$imageUrl"
                                } else {
                                    "http:$imageUrl"
                                }
                            }
                            linkOpenGraph["image"] = imageUrl
                        }
                    }
                }
            }
            val tempImage = linkOpenGraph["image"] ?: ""
            val tempTitle = linkOpenGraph["title"] ?: ""
            imageLink.postValue(tempImage)
            title.postValue(tempTitle)
            saveLinkWithoutFolder(link, tempTitle, tempImage)
            isLinkSaved.postValue(true)
        }
    }

    private fun saveLinkWithoutFolder(savedLink: String, title: String, imageLink: String) {
        val newLinks = SharedPrefHelper.getNewLinks(getApplication<Application>().applicationContext)
        with(newLinks.edit()) {
            if (newLinks.getString(savedLink, null) == null) {
                val json = JSONObject()
                json.put("image_link", imageLink)
                json.put("title", title)
                json.put("created_at", getCurrentDateTime())
                val result = json.convert()
                putString(savedLink, result)
                apply()
            }
        }
    }

    fun saveLinkWithFolder(folder: FolderModel) {
        val newLinks = SharedPrefHelper.getNewLinks(getApplication<Application>().applicationContext)
        with(newLinks.edit()) {
            val json = JSONObject()
            json.put("title", title.value)
            json.put("folder_name", folder.name)
            json.put("image_link", imageLink)
            json.put("created_at", getCurrentDateTime())
            putString(savedLink.value, json.convert())
            apply()
        }

        val db = dbHelper.writableDatabase
        val cv = ContentValues().apply {
            put(ShareContract.Folder.imageLink, folder.imageUrl)
        }
        db.update(
            ShareContract.Folder.table,
            cv,
            "${ShareContract.Folder.folderName} = ?",
            arrayOf(folder.name)
        )
        db.close()
    }

    fun getFoldersFromDB(): MutableList<FolderModel> {
        val db = dbHelper.readableDatabase
        val folderColumns =
            arrayOf(
                ShareContract.Folder.seq,
                ShareContract.Folder.folderName,
                ShareContract.Folder.visible,
                ShareContract.Folder.imageLink
            )

        val folderCursor =
            db.query(
                ShareContract.Folder.table,
                folderColumns,
                null,
                null,
                null,
                null,
                "${ShareContract.Folder.time} DESC"
            )

        val folders = mutableListOf<FolderModel>()
        folders.addAll(
            getFolders(
                folderCursor,
            )
        )
        db.close()

        for (folder in folders) {
            Log.i(LinkPoolApp.TAG, folder.toString())
        }

        return folders
    }

    private fun getFolders(
        folderCursor: Cursor
    ): MutableList<FolderModel> {
        val folders = mutableListOf<FolderModel>()
        with(folderCursor) {
            while (moveToNext()) {
                val folderName =
                    getString(getColumnIndexOrThrow(ShareContract.Folder.folderName))
                val visible = getInt(getColumnIndexOrThrow(ShareContract.Folder.visible)) == 1
                val imageLink =
                    getString(getColumnIndexOrThrow(ShareContract.Folder.imageLink))

                folders.add(
                    FolderModel(
                        FolderType.One,
                        imageLink,
                        folderName,
                        visible
                    )
                )
            }
        }
        folderCursor.close()
        return folders
    }


}