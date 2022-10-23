package com.mr.ac_project_app.view.share

import android.app.Application
import android.content.ContentValues
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType

class ShareViewModel(application: Application) : AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }


    fun saveLinkWithoutFolder(savedLink: String): Long {
        val db = dbHelper.writableDatabase
        val values = ContentValues().apply {
            put(ShareContract.LinkTempEntry.link, savedLink)
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
                    getImageLinks(
                        db,
                        ShareContract.LinkTempEntry.table,
                        linkColumns,
                        ShareContract.LinkTempEntry.folderSeq,
                        seq
                    )
                val linkCursor =
                    getImageLinks(
                        db,
                        ShareContract.LinkEntry.table,
                        linkColumns,
                        ShareContract.LinkEntry.folderSeq,
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

                when (imageLinks.size) {
                    1 -> {
                        folders.add(
                            FolderModel(
                                FolderType.One,
                                imageLinks,
                                folderName,
                                visible,
                                seq
                            )
                        )
                    }
                    2 -> {
                        folders.add(
                            FolderModel(
                                FolderType.Double,
                                imageLinks,
                                folderName,
                                visible,
                                seq
                            )
                        )
                    }
                    3 -> {
                        folders.add(
                            FolderModel(
                                FolderType.Triple,
                                imageLinks,
                                folderName,
                                visible,
                                seq
                            )
                        )
                    }
                    else -> {
                        folders.add(
                            FolderModel(
                                FolderType.None,
                                imageLinks,
                                folderName,
                                visible,
                                seq
                            )
                        )
                    }
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

    private fun getImageLinks(
        db: SQLiteDatabase,
        table: String,
        linkColumns: Array<String>,
        folderSeq: String,
        seq: Long
    ) = db.query(
        table,
        linkColumns,
        "$folderSeq = ?",
        arrayOf("$seq"),
        null,
        null,
        null,
        "3"
    )
}