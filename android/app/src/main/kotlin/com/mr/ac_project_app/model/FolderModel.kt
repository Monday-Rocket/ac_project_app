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
                FolderModel(FolderType.None, arrayListOf(), name, private)
            } else {
                when (imageUrlList.size) {
                    1 -> {
                        FolderModel(FolderType.One, imageUrlList, name, private)
                    }
                    2 -> {
                        FolderModel(FolderType.Double, imageUrlList, name, private)
                    }
                    else -> {
                        FolderModel(FolderType.Triple, imageUrlList, name, private)
                    }
                }
            }
        }
    }
}
