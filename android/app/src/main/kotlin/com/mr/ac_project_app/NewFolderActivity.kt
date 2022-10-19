package com.mr.ac_project_app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.inputmethod.EditorInfo
import android.widget.Toast
import android.window.OnBackInvokedDispatcher
import android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.mr.ac_project_app.databinding.ActivityNewFolderBinding

class NewFolderActivity : ComponentActivity() {

    private lateinit var binding: ActivityNewFolderBinding
    private var folderVisibility = false
    private lateinit var callback: OnBackPressedCallback

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityNewFolderBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.background.setOnClickListener {
            Toast.makeText(applicationContext, "터치됨", Toast.LENGTH_SHORT).show()
        }

        binding.backButton.setOnClickListener {
            val intent = Intent(this@NewFolderActivity, ShareActivity::class.java)
            startActivity(intent)
            finish()
            overridePendingTransition(R.anim.slide_left_enter, R.anim.slide_left_exit)
        }

        setInputFolderName()

        binding.completeText.setOnClickListener {
            if (binding.inputNewFolderText.text.toString().isNotEmpty()) {
                binding.saveFolderButton.callOnClick()
            }
        }

        binding.visibleToggleButton.setOnClickListener {
            folderVisibility = !folderVisibility
        }

        binding.saveFolderButton.setOnClickListener {
            val intent = Intent(this@NewFolderActivity, SaveSuccessActivity::class.java)
            intent.putExtra("folderVisibility", folderVisibility)
            intent.putExtra("folderName", binding.inputNewFolderText.text.toString())
            intent.putExtra("title", "새 폴더에 저장 완료!")
            startActivity(intent)
            finish()
        }

        callback = object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                binding.backButton.callOnClick()
            }
        }

        onBackPressedDispatcher.addCallback(callback)
    }


    @SuppressLint("ClickableViewAccessibility")
    private fun setInputFolderName() {
        binding.inputNewFolderText.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0)

        binding.inputNewFolderText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {

            }

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {

            }

            override fun afterTextChanged(s: Editable?) {
                if (binding.inputNewFolderText.text.toString() != "") {
                    binding.inputNewFolderText.setCompoundDrawablesWithIntrinsicBounds(
                        0,
                        0,
                        R.drawable.btn_x_small,
                        0
                    )
                    binding.completeText.setTextColor(getColor(R.color.grey800))
                    binding.saveFolderButton.isEnabled = true
                } else {
                    binding.inputNewFolderText.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0)
                    binding.completeText.setTextColor(getColor(R.color.grey300))
                    binding.saveFolderButton.isEnabled = false
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

        binding.inputNewFolderText.setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                Toast.makeText(applicationContext, "확인", Toast.LENGTH_SHORT).show()
                keyBordHide()
            }
            false
        }
    }

    fun keyBordHide() {
        val window: Window = window
        WindowInsetsControllerCompat(
            window,
            window.decorView
        ).hide(WindowInsetsCompat.Type.ime())
    }

    fun keyBordShow() {
        val window: Window = window
        WindowInsetsControllerCompat(
            window,
            window.decorView
        ).show(WindowInsetsCompat.Type.ime())
    }
}