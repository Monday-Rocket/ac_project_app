package com.mr.ac_project_app

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.widget.Toast
import com.mr.ac_project_app.databinding.ActivityNewFolderBinding

class NewFolderActivity : Activity() {

    private lateinit var binding: ActivityNewFolderBinding

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityNewFolderBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.background.setOnClickListener {
            Toast.makeText(applicationContext, "터치됨", Toast.LENGTH_SHORT).show()
        }

        binding.inputNewFolderText.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0)

        binding.inputNewFolderText.addTextChangedListener(object : TextWatcher{
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {

            }

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {

            }

            override fun afterTextChanged(s: Editable?) {
                if (binding.inputNewFolderText.text.toString() != "") {
                    binding.inputNewFolderText.setCompoundDrawablesWithIntrinsicBounds(0, 0, R.drawable.btn_x_small, 0)
                }
            }

        })

        binding.inputNewFolderText.setOnTouchListener(object : View.OnTouchListener {
            override fun onTouch(v: View?, event: MotionEvent): Boolean {
                val right = 2
                if (event.action == MotionEvent.ACTION_UP && binding.inputNewFolderText.text.toString() != "") {
                    if (event.rawX >= binding.inputNewFolderText.right - binding.inputNewFolderText.compoundDrawables[right].bounds.width()
                    ) {
                        binding.inputNewFolderText.setText("")
                        return true
                    }
                }
                return false
            }
        })

        binding.visibleToggleButton.setOnClickListener {

        }
    }
}