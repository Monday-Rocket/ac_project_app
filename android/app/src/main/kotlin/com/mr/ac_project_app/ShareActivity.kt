package com.mr.ac_project_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.widget.Toast
import com.mr.ac_project_app.databinding.ActivityShareBinding


class ShareActivity : Activity() {

    private var resultData: String = ""
    private lateinit var binding: ActivityShareBinding

    companion object {
        const val SHARED_PREF = "share_pref"
        const val SHARE_LIST_ID = "sharedDataList"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityShareBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)

//        binding.button.setOnClickListener {
//            Log.i("ACP", dataDir.absolutePath)
//            writeSharedPref(resultData)
//            finishAffinity()
//        }
    }

    private fun writeSharedPref(contents: String) {
        val sharedPref = getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)
        val saved = sharedPref.getStringSet(SHARE_LIST_ID, HashSet<String>())!!
        val resultSet = HashSet<String>()
        resultSet.addAll(saved)
        resultSet.add(contents)
        sharedPref.edit().putStringSet(SHARE_LIST_ID, resultSet).apply()
    }


    override fun onResume() {
        super.onResume()
        resultData = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (TextUtils.isEmpty(resultData)) {
            resultData = intent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""
        }
        Toast.makeText(applicationContext, resultData, Toast.LENGTH_SHORT).show()
        Log.i("ACP", "onResume:: $resultData")
    }

    override fun onPause() {
        super.onPause()
        finishAffinity()
    }
}