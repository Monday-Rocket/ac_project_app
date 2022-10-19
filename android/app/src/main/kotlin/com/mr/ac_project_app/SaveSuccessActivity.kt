package com.mr.ac_project_app

import android.net.Uri
import android.os.Bundle
import android.view.View
import androidx.activity.ComponentActivity
import androidx.core.content.res.ResourcesCompat
import com.bumptech.glide.Glide
import com.mr.ac_project_app.databinding.ActivitySuccessBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType

class SaveSuccessActivity: ComponentActivity() {

    private lateinit var binding: ActivitySuccessBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySuccessBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.background.setOnClickListener {
            finishAffinity()
        }

        val title = intent.getStringExtra("title") ?: ""
        binding.titleSuccessTextView.text = title

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
                        if (folder.private) View.VISIBLE else View.GONE
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
                        if (folder.private) View.VISIBLE else View.GONE
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
                        if (folder.private) View.VISIBLE else View.GONE
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
                        if (folder.private) View.VISIBLE else View.GONE
                }
            }
        }
    }
}