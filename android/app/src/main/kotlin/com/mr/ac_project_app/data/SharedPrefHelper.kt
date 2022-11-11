package com.mr.ac_project_app.data

import android.content.Context
import android.content.SharedPreferences
import com.mr.ac_project_app.R

object SharedPrefHelper {
    fun getNewLinks(context: Context): SharedPreferences {
        return context.getSharedPreferences(
            context.getString(R.string.preference_new_links),
            Context.MODE_PRIVATE
        )
    }

    fun getNewFolders(context: Context): SharedPreferences {
        return context.getSharedPreferences(
            context.getString(R.string.preference_new_folders),
            Context.MODE_PRIVATE
        )
    }
}