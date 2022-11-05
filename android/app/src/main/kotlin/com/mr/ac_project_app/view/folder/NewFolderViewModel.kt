package com.mr.ac_project_app.view.folder

import android.app.Application
import android.content.ContentValues
import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.R
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.utils.convert
import org.json.JSONObject

class NewFolderViewModel(application: Application): AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun saveNewFolder(name: String, link: String, visible: Boolean, imageLink: String) {

        val newFolders = getNewFolders()
        with(newFolders.edit()) {
            val json = JSONObject()
            json.put("name", name)
            json.put("visible", visible)
            putString(link, json.convert())
            apply()
        }

        val newLinks = getNewLinks()
        with(newLinks.edit()) {
            val savedData = newLinks.getString(link, "")!!
            val json = JSONObject(savedData)
            json.put("folder_name", name)
            putString(link, json.convert())
            apply()
        }

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

    private fun getNewLinks(): SharedPreferences {
        val context = getApplication<Application>().applicationContext
        return context.getSharedPreferences(
            context.getString(R.string.preference_new_links),
            Context.MODE_PRIVATE
        )
    }

    private fun getNewFolders(): SharedPreferences {
        val context = getApplication<Application>().applicationContext
        return context.getSharedPreferences(
            context.getString(R.string.preference_new_folders),
            Context.MODE_PRIVATE
        )
    }
}