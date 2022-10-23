package com.mr.ac_project_app.view.folder

import android.app.Application
import android.content.ContentValues
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper

class NewFolderViewModel(application: Application): AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun saveTempFolderDB(name: String, link: String, visible: Boolean, linkSeq: Long): Long {
        val db = dbHelper.writableDatabase

        val values = ContentValues().apply {
            put(ShareContract.FolderTempEntry.folderName, name)
            put(ShareContract.FolderTempEntry.visible, visible)
        }
        val folderSeq = db.insert(ShareContract.FolderTempEntry.table, null, values)

        val updateColumns = ContentValues().apply {
            put(ShareContract.LinkTempEntry.link, link)
            put(ShareContract.LinkTempEntry.folderSeq, folderSeq)
            // FIXME temp image
            put(
                ShareContract.LinkTempEntry.imageLink,
                "https://i.pinimg.com/originals/82/18/c4/8218c49bb19adffbe1704a9a60ec4875.jpg"
            )
        }
        if (linkSeq != -1L) {
            db.update(
                ShareContract.LinkTempEntry.table,
                updateColumns,
                "${ShareContract.LinkTempEntry.seq} = ?",
                arrayOf("$linkSeq")
            )
        }

        db.close()
        return folderSeq
    }
}