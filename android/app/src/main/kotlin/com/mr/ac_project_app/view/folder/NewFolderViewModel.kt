package com.mr.ac_project_app.view.folder

import android.app.Application
import android.content.ContentValues
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.data.ShareContract
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.data.SharedPrefHelper
import com.mr.ac_project_app.utils.convert
import com.mr.ac_project_app.utils.getCurrentDateTime
import org.json.JSONObject

class NewFolderViewModel(application: Application): AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun saveNewFolder(name: String, link: String, visible: Boolean, imageLink: String) {

        val context = getApplication<Application>().applicationContext

        val newFolders = SharedPrefHelper.getNewFolders(context)
        with(newFolders.edit()) {
            val json = JSONObject()
            json.put("name", name)
            json.put("visible", visible)
            json.put("created_at", getCurrentDateTime())

            val set = HashSet(newFolders.getStringSet("new_folders", HashSet())!!)
            set.add(json.convert())
            putStringSet("new_folders", set)
            apply()
        }

        val newLinks = SharedPrefHelper.getNewLinks(context)
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
}