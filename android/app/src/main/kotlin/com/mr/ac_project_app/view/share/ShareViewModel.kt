package com.mr.ac_project_app.view.share

import android.app.Application
import android.text.TextUtils
import android.webkit.URLUtil
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.MutableLiveData
import com.mr.ac_project_app.data.ShareDBFunctions
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.data.SharedPrefHelper
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.utils.convert
import com.mr.ac_project_app.utils.getCurrentDateTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.jsoup.Jsoup

class ShareViewModel(application: Application) : AndroidViewModel(application) {

    private var dbHelper: ShareDbHelper
    var savedLink = MutableLiveData("")
    var imageLink = MutableLiveData<String>()
    private var title = MutableLiveData<String>()
    private var isLinkSaved = MutableLiveData(false)

    init {
        dbHelper = ShareDbHelper(context = getApplication<Application>().applicationContext)
    }

    fun saveLink(link: String): Boolean {
        if (isLinkSaved.value!!) {
            return false
        }
        if (TextUtils.isEmpty(link) || !URLUtil.isValidUrl(link)) {
            return true
        }
        savedLink.postValue(link)
        CoroutineScope(Dispatchers.IO).launch {
            val linkOpenGraph = HashMap<String, String>()
            val document = Jsoup.connect(link).get()
            val elements = document.select("meta[property^=og:]")
            elements?.let {
                it.forEach { item ->
                    when (item.attr("property")) {
                        "og:url" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("url", content)
                            }
                        }
                        "og:site_name" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("siteName", content)
                            }
                        }
                        "og:title" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("title", content)
                            }
                        }
                        "og:description" -> {
                            item.attr("content")?.let { content ->
                                linkOpenGraph.put("description", content)
                            }
                        }
                        "og:image" -> {
                            var imageUrl = item.attr("content")
                            if (!imageUrl.contains("http")) {
                                imageUrl = if (link.contains("https")) {
                                    "https:$imageUrl"
                                } else {
                                    "http:$imageUrl"
                                }
                            }
                            linkOpenGraph["image"] = imageUrl
                        }
                    }
                }
            }
            val tempImage = linkOpenGraph["image"] ?: ""
            val tempTitle = linkOpenGraph["title"] ?: ""
            imageLink.postValue(tempImage)
            title.postValue(tempTitle)
            saveLinkWithoutFolder(link, tempTitle, tempImage)
            isLinkSaved.postValue(true)
        }
        return false
    }

    private fun saveLinkWithoutFolder(savedLink: String, title: String, imageLink: String) {
        val newLinks = SharedPrefHelper.getNewLinks(getApplication<Application>().applicationContext)
        with(newLinks.edit()) {
            if (newLinks.getString(savedLink, null) == null) {
                val json = JSONObject()
                json.put("image_link", imageLink)
                json.put("title", title)
                json.put("created_at", getCurrentDateTime())
                val result = json.convert()
                putString(savedLink, result)
                apply()
            }
        }
    }

    fun saveLinkWithFolder(folder: FolderModel) {
        val newLinks = SharedPrefHelper.getNewLinks(getApplication<Application>().applicationContext)
        with(newLinks.edit()) {
            val json = JSONObject()
            json.put("title", title.value)
            json.put("folder_name", folder.name)
            json.put("image_link", imageLink.value)
            json.put("created_at", getCurrentDateTime())
            putString(savedLink.value, json.convert())
            apply()
        }
        ShareDBFunctions.saveLink(dbHelper, folder)
    }

    fun getFoldersFromDB(): Collection<FolderModel> {
        return ShareDBFunctions.getFoldersFromDB(dbHelper)
    }
}