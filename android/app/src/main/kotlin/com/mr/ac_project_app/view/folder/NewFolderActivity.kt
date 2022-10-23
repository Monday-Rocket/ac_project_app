package com.mr.ac_project_app.view.folder

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.inputmethod.EditorInfo
import androidx.activity.OnBackPressedCallback
import androidx.activity.viewModels
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.fragment.app.FragmentActivity
import com.mr.ac_project_app.R
import com.mr.ac_project_app.view.SaveSuccessActivity
import com.mr.ac_project_app.databinding.ActivityNewFolderBinding
import com.mr.ac_project_app.dialog.ConfirmDialogInterface
import com.mr.ac_project_app.dialog.MessageDialog
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.view.share.ShareActivity

class NewFolderActivity : FragmentActivity(), ConfirmDialogInterface {

    private var linkSeq: Long = -1L
    private lateinit var binding: ActivityNewFolderBinding
    private var folderVisibility = true
    private lateinit var callback: OnBackPressedCallback

    private val viewModel: NewFolderViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityNewFolderBinding.inflate(layoutInflater)
        setContentView(binding.root)

        linkSeq = intent.getLongExtra("linkSeq", -1L)

        binding.background.setOnClickListener {
            val dialog = MessageDialog(
                title = "새 폴더를 만들고 있어요",
                content = "지금 폴더 만들기를 그만두신다면\n" + "링크는 폴더에 담기지 않은 채로 저장돼요!",
                confirmDialogInterface = this,
                imageId = R.drawable.folder_icon,
                buttonText = "다음에 만들기"
            )
            dialog.isCancelable = true
            dialog.show(supportFragmentManager, "Folder Cancel Dialog")
        }

        setBackButton()

        setFolderNameEditText()

        binding.completeText.setOnClickListener {
            if (binding.folderNameEditText.text.toString().isNotEmpty()) {
                binding.saveFolderButton.callOnClick()
            }
        }

        binding.visibleToggleButton.setOnClickListener {
            folderVisibility = !folderVisibility
        }

        binding.saveFolderButton.setOnClickListener {

            val link = intent.getStringExtra("link") ?: ""

            val folderSeq = viewModel.saveTempFolderDB(
                binding.folderNameEditText.text.toString(),
                link,
                folderVisibility,
                linkSeq
            )

            val movingIntent = Intent(this@NewFolderActivity, SaveSuccessActivity::class.java)
            val folderName = binding.folderNameEditText.text.toString()
            // FIXME temp image
            movingIntent.putExtra(
                "folder",
                FolderModel.create(
                    listOf("https://i.pinimg.com/originals/82/18/c4/8218c49bb19adffbe1704a9a60ec4875.jpg"),
                    folderName,
                    folderVisibility,
                    folderSeq
                )
            )
            movingIntent.putExtra("saveType", SaveType.New)
            movingIntent.putExtra("linkSeq", linkSeq)
            startActivity(movingIntent)
            finish()
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
        }

    }

    private fun setBackButton() {
        binding.backButton.setOnClickListener {
            val intent = Intent(this@NewFolderActivity, ShareActivity::class.java)
            startActivity(intent)
            finish()
            overridePendingTransition(R.anim.slide_left_enter, R.anim.slide_left_exit)
        }

        callback = object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                binding.backButton.callOnClick()
            }
        }

        onBackPressedDispatcher.addCallback(callback)
    }


    @SuppressLint("ClickableViewAccessibility")
    private fun setFolderNameEditText() {
        binding.folderNameEditText.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0)

        binding.folderNameEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {

            }

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {

            }

            override fun afterTextChanged(s: Editable?) {
                if (binding.folderNameEditText.text.toString() != "") {
                    binding.folderNameEditText.setCompoundDrawablesWithIntrinsicBounds(
                        0, 0, R.drawable.btn_x_small, 0
                    )
                    binding.completeText.setTextColor(getColor(R.color.grey800))
                    binding.saveFolderButton.isEnabled = true
                } else {
                    binding.folderNameEditText.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0)
                    binding.completeText.setTextColor(getColor(R.color.grey300))
                    binding.saveFolderButton.isEnabled = false
                }
            }

        })

        binding.folderNameEditText.setOnTouchListener(object : View.OnTouchListener {
            override fun onTouch(v: View?, event: MotionEvent): Boolean {
                val right = 2
                if (event.action == MotionEvent.ACTION_UP && binding.folderNameEditText.text.toString() != "") {
                    if (event.rawX >= binding.folderNameEditText.right - binding.folderNameEditText.compoundDrawables[right].bounds.width()) {
                        binding.folderNameEditText.setText("")
                        return true
                    }
                }
                return false
            }
        })

        binding.folderNameEditText.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                hideKeyboard()
            }
            false
        }
    }

    private fun hideKeyboard() {
        val window: Window = window
        WindowInsetsControllerCompat(
            window, window.decorView
        ).hide(WindowInsetsCompat.Type.ime())
    }

    override fun onButtonClick() {
        finishAffinity()
    }

    override fun onButtonClose() {
        finishAffinity()
    }
}