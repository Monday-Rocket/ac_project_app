package com.mr.ac_project_app.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class FolderModel(
    val type: FolderType,
    val imageUrl: String?,
    val name: String,
    val visible: Boolean,
) : Parcelable {
    companion object {
        fun create(imageUrl: String?, name: String, visible: Boolean): FolderModel {
            return FolderModel(FolderType.One, imageUrl, name, visible)
        }
    }

    fun changeImageUrl(imageUrl: String): FolderModel {
        return create(imageUrl, name, visible)
    }
}
