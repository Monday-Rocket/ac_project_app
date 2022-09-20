package com.mr.ac_project_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.widget.Toast
import com.mr.ac_project_app.databinding.ActivityShareBinding
import java.io.*


class ShareActivity : Activity() {

    private var resultData: String = ""
    private lateinit var binding: ActivityShareBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityShareBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)

        binding.button.setOnClickListener {
            Log.i("ACP", dataDir.absolutePath)
            writeTextFile(resultData)
            finishAffinity()
        }
    }

    private fun writeTextFile(contents: String) {
        try {
            val absolutePath = dataDir.absolutePath
            val dir = File(absolutePath)
            if (!dir.exists()) { dir.mkdir() }
            //파일 output stream 생성
            val fos = FileOutputStream("$absolutePath/app_flutter/share.txt", true)
            val writer = BufferedWriter(OutputStreamWriter(fos))
            writer.write(contents + "\n")
            writer.flush()
            writer.close()
            fos.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
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