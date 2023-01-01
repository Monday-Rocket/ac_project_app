package com.mr.ac_project_app.view.folder

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.mr.ac_project_app.data.ShareDBFunctions
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

    fun saveNewFolder(name: String, link: String, visible: Boolean, imageLink: String): Boolean {

        val result = ShareDBFunctions.saveNewFolder(dbHelper, name, visible, imageLink)
        if (result) {
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
        }
        return result
    }
}