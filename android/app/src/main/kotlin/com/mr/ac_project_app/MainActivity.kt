package com.mr.ac_project_app

import com.mr.ac_project_app.data.SharedPrefHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

@Suppress("UNCHECKED_CAST")
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNewLinks" -> {
                    val linkSharedPref = SharedPrefHelper.getNewLinks(context)

                    val newLinkMap = HashMap<String, String>()
                    for (link in linkSharedPref.all.keys) {
                        val linkData = linkSharedPref.getString(link, "") ?: ""
                        newLinkMap[link] = linkData
                    }
                    result.success(newLinkMap)
                }
                "getNewFolders" -> {
                    val folderSharedPref = SharedPrefHelper.getNewFolders(context)
                    val linksJsonHashSet = folderSharedPref.getStringSet(context.getString(R.string.preference_new_folders), HashSet())
                    result.success(linksJsonHashSet!!.toList())
                }
                "clearData" -> {
                    try {
                        SharedPrefHelper.clear(context)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    companion object {
        private const val CHANNEL = "share_data_provider"
    }
}
