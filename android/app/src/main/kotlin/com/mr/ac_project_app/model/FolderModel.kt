package com.mr.ac_project_app.model

data class FolderModel(
    val type: FolderType,
    val imageUrlList: List<String>,
    val name: String,
    val private: Boolean
) {
    companion object {
        fun create(imageUrlList: List<String>, name: String, private: Boolean): FolderModel {
            return if (imageUrlList.isEmpty()) {
                FolderModel(FolderType.None, arrayListOf(), name, false)
            } else {
                if (imageUrlList.size == 1) {
                    FolderModel(FolderType.One, imageUrlList, name, false)
                } else if (imageUrlList.size == 2) {
                    FolderModel(FolderType.Double, imageUrlList, name, false)
                } else {
                    if (private) {
                        FolderModel(FolderType.PrivateTriple, imageUrlList, name, true)
                    } else {
                        FolderModel(FolderType.PublicTriple, imageUrlList, name, false)
                    }
                }
            }
        }
    }
}
