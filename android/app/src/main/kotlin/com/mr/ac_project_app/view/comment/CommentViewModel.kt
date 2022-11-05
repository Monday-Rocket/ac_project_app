package com.mr.ac_project_app.view.comment

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.R
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.utils.convert
import org.json.JSONObject

class CommentViewModel(application: Application): AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun addComment(link: String, comment: String) {
        val newLinks = getNewLinks()
        with(newLinks.edit()) {
            val json = JSONObject(newLinks.getString(link, "")!!)
            json.put("comment", comment)
            putString(link, json.convert())
            apply()
        }
    }

    private fun getNewLinks(): SharedPreferences {
        val context = getApplication<Application>().applicationContext
        return context.getSharedPreferences(
            context.getString(R.string.preference_new_links),
            Context.MODE_PRIVATE
        )
    }

}