package com.mr.ac_project_app.data

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import java.util.HashMap

object ShareDBFunctions {

    fun saveLink(dbHelper: ShareDbHelper, folder: FolderModel) {
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

    fun getFoldersFromDB(dbHelper: ShareDbHelper): MutableList<FolderModel> {
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

    fun saveNewFolder(
        dbHelper: ShareDbHelper,
        name: String,
        visible: Boolean,
        imageLink: String
    ) {
        val db = dbHelper.writableDatabase
        val cv = ContentValues().apply {
            put(ShareContract.Folder.folderName, name)
            put(ShareContract.Folder.visible, visible)
            put(ShareContract.Folder.imageLink, imageLink)
        }
        db.insert(
            ShareContract.Folder.table,
            null,
            cv
        )
        db.close()
    }
}