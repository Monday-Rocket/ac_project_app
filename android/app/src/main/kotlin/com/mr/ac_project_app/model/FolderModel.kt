package com.mr.ac_project_app.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class FolderModel(
    val type: FolderType,
    val imageUrlList: List<String>,
    val name: String,
    val visible: Boolean
): Parcelable {
    companion object {
        fun create(imageUrlList: List<String?>, name: String, private: Boolean): FolderModel {

            val realUrlList = mutableListOf<String>()

            imageUrlList.forEach {
                if (it != null && it.isNotEmpty()) {
                    realUrlList.add(it)
                } else {
                    realUrlList.add("")
                }
            }

            return if (realUrlList.isEmpty()) {
                FolderModel(FolderType.None, arrayListOf(), name, private)
            } else {
                when (realUrlList.size) {
                    1 -> {
                        FolderModel(FolderType.One, realUrlList, name, private)
                    }
                    2 -> {
                        FolderModel(FolderType.Double, realUrlList, name, private)
                    }
                    else -> {
                        FolderModel(FolderType.Triple, realUrlList, name, private)
                    }
                }
            }
        }
    }
}
