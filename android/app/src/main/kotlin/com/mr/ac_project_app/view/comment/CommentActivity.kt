package com.mr.ac_project_app.view.comment

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Rect
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import androidx.activity.viewModels
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.fragment.app.FragmentActivity
import com.mr.ac_project_app.MainActivity
import com.mr.ac_project_app.R
import com.mr.ac_project_app.databinding.ActivityCommentBinding
import com.mr.ac_project_app.dialog.CloseDialogInterface
import com.mr.ac_project_app.dialog.ConfirmDialogInterface
import com.mr.ac_project_app.dialog.ErrorDialogInterface
import com.mr.ac_project_app.dialog.MessageDialog
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.ui.InsetsWithKeyboardAnimationCallback
import com.mr.ac_project_app.ui.InsetsWithKeyboardCallback

class CommentActivity : FragmentActivity(), ConfirmDialogInterface, ErrorDialogInterface, CloseDialogInterface {

    private lateinit var binding: ActivityCommentBinding

    private val viewModel: CommentViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityCommentBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val insetsWithKeyboardCallback = InsetsWithKeyboardCallback(window)
        ViewCompat.setOnApplyWindowInsetsListener(binding.root, insetsWithKeyboardCallback)
        ViewCompat.setWindowInsetsAnimationCallback(binding.root, insetsWithKeyboardCallback)

        val insetsWithKeyboardAnimationCallback = InsetsWithKeyboardAnimationCallback(binding.bodyLayout)
        ViewCompat.setWindowInsetsAnimationCallback(binding.bodyLayout, insetsWithKeyboardAnimationCallback)

        val saveType = intent.getSerializableExtra("saveType") as SaveType

        binding.background.setOnClickListener {
            showCancelDialog()
        }

        binding.closeButton.setOnClickListener {
            showCancelDialog()
        }

        setCommentEditText()

        binding.saveCommentButton.setOnClickListener {

            val link = intent.getStringExtra("link") ?: ""
            val comment = binding.commentTextField.text

            if (comment.length > 500) {
                val dialog = MessageDialog(
                    title = "????????? ??????",
                    content = "?????? ???????????? 500??? ?????????\n??????????????????",
                    errorDialogInterface = this,
                    imageId = null,
                    buttonText = "??????",
                )
                dialog.isCancelable = true
                dialog.show(supportFragmentManager, "Comment Not Saved Dialog")
            } else {
                viewModel.addComment(link, comment.toString())

                val saveText = if (saveType == SaveType.New) "???" else "?????????"
                val contentText = "$saveText ????????? ????????? ???????????? ????????????"
                val dialog = MessageDialog(
                    title = "????????????!",
                    content = contentText,
                    confirmDialogInterface = this,
                    imageId = null,
                    buttonText = "????????????"
                )
                dialog.isCancelable = true
                dialog.show(supportFragmentManager, "Comment Saved Dialog")
            }
        }
    }

    override fun dispatchTouchEvent(event: MotionEvent?): Boolean {
        if (event?.action == MotionEvent.ACTION_DOWN) {
            val v = currentFocus
            if (v is EditText) {
                val outRect = Rect()
                v.getGlobalVisibleRect(outRect)
                if (!outRect.contains(event.rawX.toInt(), event.rawY.toInt())) {
                    v.clearFocus()
                    val imm: InputMethodManager =
                        getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.hideSoftInputFromWindow(v.getWindowToken(), 0)
                }
            }
        }
        return super.dispatchTouchEvent(event)
    }

    private fun showCancelDialog() {
        val dialog = MessageDialog(
            title = "???????????? ??????????????????",
            content = "????????? ????????? ???????????????\n" +
                    "????????? ????????? ????????? ????????????!",
            closeDialogInterface = this,
            imageId = R.drawable.comments_icon,
            buttonText = "????????? ????????????"
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
                try {
                    if (event.action == MotionEvent.ACTION_UP && binding.commentTextField.text.toString() != "") {
                        if (event.rawX >= binding.commentTextField.right - binding.commentTextField.compoundDrawables[right].bounds.width()
                        ) {
                            binding.commentTextField.setText("")
                            return true
                        }
                    }
                } catch (e: Exception) {
                    return true
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
        val intent = Intent(this@CommentActivity, MainActivity::class.java)
        startActivity(intent)
        finish()
    }

    override fun onErrorConfirmedClick() {

    }

    override fun onCloseClick() {
        finishAffinity()
    }
}