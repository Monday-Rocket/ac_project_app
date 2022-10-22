package com.mr.ac_project_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import androidx.activity.ComponentActivity
import androidx.core.content.res.ResourcesCompat
import com.bumptech.glide.Glide
import com.mr.ac_project_app.databinding.ActivitySuccessBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import com.mr.ac_project_app.model.SaveType

class SaveSuccessActivity: ComponentActivity() {

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

        when (saveType) {
            SaveType.New -> {
                binding.titleSuccessTextView.text = "새 폴더에 저장 완료!"
            }
            SaveType.Selected -> {
                binding.titleSuccessTextView.text = "선택한 폴더에 저장 완료!"
            }
        }

        binding.writeCommentButton.setOnClickListener {
            val intent = Intent(this@SaveSuccessActivity, CommentActivity::class.java)
            intent.putExtra("saveType", saveType)
            startActivity(intent)
            finish()
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
        }

        setFolderView()
    }

    private fun setFolderView() {
        val folder = intent.getParcelableExtra<FolderModel>("folder")

        if (folder != null) {
            when (folder.type) {
                FolderType.Triple -> {
                    binding.tripleLayout.root.visibility = View.VISIBLE

                    binding.tripleLayout.folderText.text = folder.name
                    binding.tripleLayout.folderText.background =
                        ResourcesCompat.getDrawable(resources, R.drawable.folder_text_back, null)

                    binding.tripleLayout.leftImage.clipToOutline = true
                    binding.tripleLayout.rightTopImage.clipToOutline = true
                    binding.tripleLayout.rightBottomImage.clipToOutline = true

                    Glide.with(binding.tripleLayout.root)
                        .load(Uri.parse(folder.imageUrlList[0]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_left)
                        .into(binding.tripleLayout.leftImage)
                    Glide.with(binding.tripleLayout.root)
                        .load(Uri.parse(folder.imageUrlList[1]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_right_top)
                        .into(binding.tripleLayout.rightTopImage)
                    Glide.with(binding.tripleLayout.root)
                        .load(Uri.parse(folder.imageUrlList[2]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_right_bottom)
                        .into(binding.tripleLayout.rightBottomImage)

                    binding.tripleLayout.lockImage.visibility =
                        if (folder.visible) View.GONE else View.VISIBLE
                }
                FolderType.Double -> {
                    binding.doubleLayout.root.visibility = View.VISIBLE

                    binding.doubleLayout.folderText.text = folder.name
                    binding.doubleLayout.folderText.background =
                        ResourcesCompat.getDrawable(resources, R.drawable.folder_text_back, null)

                    binding.doubleLayout.leftImage.clipToOutline = true
                    binding.doubleLayout.rightImage.clipToOutline = true

                    Glide.with(binding.doubleLayout.root)
                        .load(Uri.parse(folder.imageUrlList[0]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_left)
                        .into(binding.doubleLayout.leftImage)
                    Glide.with(binding.doubleLayout.root)
                        .load(Uri.parse(folder.imageUrlList[1]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_right)
                        .into(binding.doubleLayout.rightImage)

                    binding.doubleLayout.lockImage.visibility =
                        if (folder.visible) View.GONE else View.VISIBLE
                }
                FolderType.One -> {

                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = folder.name
                    binding.oneLayout.folderText.background =
                        ResourcesCompat.getDrawable(resources, R.drawable.folder_text_back, null)

                    binding.oneLayout.oneImage.clipToOutline = true

                    Glide.with(binding.oneLayout.root)
                        .load(Uri.parse(folder.imageUrlList[0]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_one)
                        .into(binding.oneLayout.oneImage)

                    binding.oneLayout.lockImage.visibility =
                        if (folder.visible) View.GONE else View.VISIBLE
                }
                else -> {
                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = folder.name
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