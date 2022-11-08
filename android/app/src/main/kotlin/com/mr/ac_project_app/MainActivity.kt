package com.mr.ac_project_app

import android.content.Context
import com.mr.ac_project_app.view.share.ShareActivity.Companion.SHARED_PREF

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNewLinks") {
                val sharedPref = activity.getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)
                val linksJsonString = sharedPref.getString(context.getString(R.string.preference_new_links), "")
                result.success(linksJsonString)
            } else if (call.method == "getNewFolders") {
                val sharedPref = activity.getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)
                val linksJsonString = sharedPref.getString(context.getString(R.string.preference_new_folders), "")
                result.success(linksJsonString)
            } else {
                result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL = "share_data_provider"
    }
}
