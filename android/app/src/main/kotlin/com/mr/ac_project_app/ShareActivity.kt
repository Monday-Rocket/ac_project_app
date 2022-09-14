package com.mr.ac_project_app

import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import com.mr.ac_project_app.databinding.ActivityShareBinding


class ShareActivity: Activity() {

    private lateinit var binding: ActivityShareBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityShareBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)

        binding.button.setOnClickListener {
            finishAffinity()
        }
    }

    override fun onResume() {
        super.onResume()
        Toast.makeText(applicationContext, "onResume", Toast.LENGTH_SHORT).show()
        var msg = this.intent.getStringExtra("KEY") //전송부의 키값의 value를 가져온다.
        Log.i("ACP","onResume:: $msg")
    }

    override fun onPause() {
        super.onPause()
        finishAffinity()
    }
}