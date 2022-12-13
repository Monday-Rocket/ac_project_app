package com.mr.ac_project_app

import com.jakewharton.threetenabp.AndroidThreeTen
import io.flutter.app.FlutterApplication

class LinkPoolApp: FlutterApplication() {
    companion object {
        const val TAG = "LinkPoolApp"
    }

    override fun onCreate() {
        super.onCreate()
        AndroidThreeTen.init(this);
    }
}