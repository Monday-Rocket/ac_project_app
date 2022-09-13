package com.mr.ac_project_app

import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.appcompat.app.AppCompatActivity
import kotlinx.android.synthetic.main.activity_share.*


class ShareActivity: ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_share)

        button.setOnClickListener {
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