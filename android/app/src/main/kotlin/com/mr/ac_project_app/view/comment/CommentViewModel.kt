package com.mr.ac_project_app.view.comment

import android.app.Application
import android.content.ContentValues
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper

class CommentViewModel(application: Application): AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun addComment(linkSeq: Long, comment: String) {
        val db = dbHelper.writableDatabase

        val values = ContentValues().apply {
            put(ShareContract.LinkTempEntry.comment, comment)
        }

        db.update(ShareContract.LinkTempEntry.table, values, "${ShareContract.LinkTempEntry.seq} = ?", arrayOf("$linkSeq"))
        db.close()
    }
}