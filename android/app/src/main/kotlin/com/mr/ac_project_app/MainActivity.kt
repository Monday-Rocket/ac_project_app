package com.mr.ac_project_app

import android.content.Context
import com.mr.ac_project_app.ShareActivity.Companion.SHARED_PREF
import com.mr.ac_project_app.ShareActivity.Companion.SHARE_LIST_ID
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getShareData") {
                val sharedPref = activity.getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)
                val resultSet = sharedPref.getStringSet(SHARE_LIST_ID, HashSet())!!
                result.success(resultSet.toList())
            } else {
                result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL = "share_data_provider"
    }
}
