package com.mr.ac_project_app.data

import android.provider.BaseColumns

object ShareContract {
    object Folder: BaseColumns {
        const val table = "folder"
        const val seq = "seq"
        const val folderName = "name"
        const val visible = "visible"
        const val imageLink = "imageLink"
        const val time = "time"
    }
}