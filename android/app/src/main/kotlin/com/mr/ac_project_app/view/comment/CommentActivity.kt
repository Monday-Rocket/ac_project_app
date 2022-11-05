package com.mr.ac_project_app.view.comment

import android.annotation.SuppressLint
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.inputmethod.EditorInfo
import androidx.activity.viewModels
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.fragment.app.FragmentActivity
import com.mr.ac_project_app.R
import com.mr.ac_project_app.databinding.ActivityCommentBinding
import com.mr.ac_project_app.dialog.ConfirmDialogInterface
import com.mr.ac_project_app.dialog.MessageDialog
import com.mr.ac_project_app.model.SaveType

class CommentActivity : FragmentActivity(), ConfirmDialogInterface {

    private lateinit var binding: ActivityCommentBinding

    private val viewModel: CommentViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityCommentBinding.inflate(layoutInflater)
        setContentView(binding.root)

        @Suppress("DEPRECATION")
        val saveType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getSerializableExtra("saveType", SaveType::class.java)
        } else {
            intent.getSerializableExtra("saveType") as SaveType
        }

        binding.background.setOnClickListener {
            showCancelDialog()
        }

        binding.closeButton.setOnClickListener {
            showCancelDialog()
        }

        setCommentEditText()

        binding.saveCommentButton.setOnClickListener {

            val link = intent.getStringExtra("link") ?: ""
            viewModel.addComment(link, binding.commentTextField.text.toString())

            val saveText = if (saveType == SaveType.New) "새" else "선택한"
            val contentText = "$saveText 폴더에 링크와 코멘트가 담겼어요"
            val dialog = MessageDialog(
                title = "저장완료!",
                content = contentText,
                confirmDialogInterface = this,
                imageId = null,
                buttonText = "확인하기"
            )
            dialog.isCancelable = true
            dialog.show(supportFragmentManager, "Comment Saved Dialog")
        }
    }

    private fun showCancelDialog() {
        val dialog = MessageDialog(
            title = "코멘트를 작성중이에요",
            content = "코멘트 작성을 그만두셔도\n" +
                    "링크는 선택한 폴더에 저장돼요!",
            confirmDialogInterface = this,
            imageId = R.drawable.comments_icon,
            buttonText = "다음에 만들기"
        )
        dialog.isCancelable = true
        dialog.show(supportFragmentManager, "Comment Cancel Dialog")
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setCommentEditText() {

        binding.commentTextField.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {

            }

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {

            }

            override fun afterTextChanged(s: Editable?) {
                binding.saveCommentButton.isEnabled = binding.commentTextField.text.toString() != ""
            }

        })

        binding.commentTextField.setOnTouchListener(object : View.OnTouchListener {
            override fun onTouch(v: View?, event: MotionEvent): Boolean {
                val right = 2
                if (event.action == MotionEvent.ACTION_UP && binding.commentTextField.text.toString() != "") {
                    if (event.rawX >= binding.commentTextField.right - binding.commentTextField.compoundDrawables[right].bounds.width()
                    ) {
                        binding.commentTextField.setText("")
                        return true
                    }
                }
                return false
            }
        })

        binding.commentTextField.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                hideKeyboard()
            }
            false
        }
    }

    private fun hideKeyboard() {
        val window: Window = window
        WindowInsetsControllerCompat(
            window,
            window.decorView
        ).hide(WindowInsetsCompat.Type.ime())
    }

    override fun onButtonClick() {
        finishAffinity()
    }
}