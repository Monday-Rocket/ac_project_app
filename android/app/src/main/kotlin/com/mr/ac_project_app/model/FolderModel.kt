package com.mr.ac_project_app.model

data class FolderModel(
    val type: FolderType,
    val imageUrlList: List<String>,
    val private: Boolean
)
