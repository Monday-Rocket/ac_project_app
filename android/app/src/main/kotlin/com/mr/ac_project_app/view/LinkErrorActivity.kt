package com.mr.ac_project_app.view

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import com.mr.ac_project_app.databinding.ActivityEmptyBinding
import com.mr.ac_project_app.dialog.ConfirmDialogInterface
import com.mr.ac_project_app.dialog.MessageDialog

class LinkErrorActivity: FragmentActivity(), ConfirmDialogInterface {

    private lateinit var binding: ActivityEmptyBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityEmptyBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val dialog = MessageDialog(
            title = "링크를 공유해주세요",
            content = "링풀에는 링크만 저장할 수 있어요.\n확인하고 다시 공유해주세요!",
            confirmDialogInterface = this,
            imageId = null,
            buttonText = "확인",
            mustFinished = true
        )
        dialog.isCancelable = true
        dialog.show(supportFragmentManager, "Link Error Dialog")

        binding.background.setOnClickListener {
            finishAffinity()
        }
    }

    override fun onButtonClick() {
        finishAffinity()
    }
}