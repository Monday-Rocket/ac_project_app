package com.mr.ac_project_app.data

import android.provider.BaseColumns

object ShareContract {
    object LinkTempEntry: BaseColumns {
        const val seq = "seq"
        const val table = "link_temp"
        const val link = "link"
        const val comment = "comment"
        const val folderSeq = "folder_seq"
        const val imageLink = "image_link"
        const val title = "title"
    }

    object LinkEntry: BaseColumns {
        const val seq = "seq"
        const val table = "link"
        const val link = "link"
        const val comment = "comment"
        const val folderSeq = "folder_seq"
        const val imageLink = "image_link"
        const val title = "title"
    }

    object FolderTempEntry: BaseColumns {
        const val seq = "seq"
        const val table = "folder_temp"
        const val folderName = "name"
        const val visible = "visible"
    }

    object FolderEntry: BaseColumns {
        const val seq = "seq"
        const val table = "folder"
        const val folderName = "name"
        const val visible = "visible"
    }
}