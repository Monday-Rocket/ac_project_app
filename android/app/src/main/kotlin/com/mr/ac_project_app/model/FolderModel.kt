package com.mr.ac_project_app.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class FolderModel(
    val type: FolderType,
    val imageUrl: String?,
    val name: String,
    val visible: Boolean,
    val seq: Long?,
) : Parcelable {
    companion object {
        fun create(imageUrl: String?, name: String, visible: Boolean, seq: Long?): FolderModel {
            return FolderModel(FolderType.One, imageUrl, name, visible, seq)
        }
    }

    fun changeImageUrl(imageUrl: String): FolderModel {
        return create(imageUrl, name, visible, seq)
    }
}
