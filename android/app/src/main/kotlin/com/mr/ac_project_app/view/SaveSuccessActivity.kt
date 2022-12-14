package com.mr.ac_project_app.view

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import androidx.core.content.res.ResourcesCompat
import androidx.fragment.app.FragmentActivity
import com.bumptech.glide.Glide
import com.mr.ac_project_app.MainActivity
import com.mr.ac_project_app.R
import com.mr.ac_project_app.databinding.ActivitySuccessBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.utils.getShortText
import com.mr.ac_project_app.view.comment.CommentActivity

class SaveSuccessActivity: FragmentActivity() {

    private lateinit var binding: ActivitySuccessBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySuccessBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.background.setOnClickListener {
            finishAffinity()
        }

        binding.closeButton.setOnClickListener {
            finishAffinity()
        }

        val saveType = intent.getSerializableExtra("saveType") as SaveType
        val link = intent.getStringExtra("link")

        when (saveType) {
            SaveType.New -> {
                binding.titleSuccessTextView.text = "새 폴더에 저장 완료!"
            }
            SaveType.Selected -> {
                binding.titleSuccessTextView.text = "선택한 폴더에 저장 완료!"
            }
        }

        binding.writeCommentButton.setOnClickListener {
            val movingIntent = Intent(this@SaveSuccessActivity, CommentActivity::class.java)
            movingIntent.putExtra("saveType", saveType)
            movingIntent.putExtra("link", link)
            movingIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(movingIntent)
            finish()
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
        }

        binding.moveToAppButton.setOnClickListener {
            val intent = Intent(this@SaveSuccessActivity, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
            finish()
        }

        setFolderView()
    }

    private fun setFolderView() {
        val folder = intent.getParcelableExtra<FolderModel>("folder")

        if (folder != null) {
            when (folder.type) {
                FolderType.One -> {

                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = getShortText(folder.name)
                    binding.oneLayout.folderText.background =
                        ResourcesCompat.getDrawable(resources, R.drawable.folder_text_back, null)

                    binding.oneLayout.oneImage.clipToOutline = true

                    Glide.with(binding.oneLayout.root)
                        .load(Uri.parse(folder.imageUrl))
                        .centerCrop()
                        .placeholder(R.drawable.folder_one)
                        .into(binding.oneLayout.oneImage)

                    binding.oneLayout.lockImage.visibility =
                        if (folder.visible) View.GONE else View.VISIBLE
                }
                else -> {
                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = getShortText(folder.name)
                    binding.oneLayout.folderText.background =
                        ResourcesCompat.getDrawable(resources, R.drawable.folder_text_back, null)

                    binding.oneLayout.oneImage.clipToOutline = true

                    Glide.with(binding.oneLayout.root)
                        .load(R.drawable.folder_one)
                        .centerCrop()
                        .into(binding.oneLayout.oneImage)

                    binding.oneLayout.lockImage.visibility =
                        if (folder.visible) View.GONE else View.VISIBLE
                }
            }
        }
    }
}