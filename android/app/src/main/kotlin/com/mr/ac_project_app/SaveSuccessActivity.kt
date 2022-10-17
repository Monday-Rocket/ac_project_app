package com.mr.ac_project_app

import android.app.Activity
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import com.bumptech.glide.Glide
import com.mr.ac_project_app.databinding.ActivitySuccessBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType

class SaveSuccessActivity: Activity() {

    private lateinit var binding: ActivitySuccessBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySuccessBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)

        @Suppress("DEPRECATION")
        val folder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra("folder", FolderModel::class.java)
        } else {
            intent.getParcelableExtra("folder")
        }

        if (folder != null) {
            when(folder.type) {
                FolderType.Triple -> {
                    binding.tripleLayout.root.visibility = View.VISIBLE

                    binding.tripleLayout.folderText.text = folder.name

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

                    binding.tripleLayout.lockImage.visibility = if (folder.private) View.VISIBLE else View.GONE
                }
                FolderType.Double -> {
                    binding.doubleLayout.root.visibility = View.VISIBLE

                    binding.doubleLayout.folderText.text = folder.name

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

                    binding.doubleLayout.lockImage.visibility = if (folder.private) View.VISIBLE else View.GONE
                }
                FolderType.One -> {

                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = folder.name

                    Glide.with(binding.oneLayout.root)
                        .load(Uri.parse(folder.imageUrlList[0]))
                        .centerCrop()
                        .placeholder(R.drawable.folder_one)
                        .into(binding.oneLayout.oneImage)
                }
                else -> {
                    binding.oneLayout.root.visibility = View.VISIBLE

                    binding.oneLayout.folderText.text = folder.name

                    Glide.with(binding.oneLayout.root)
                        .load(R.drawable.folder_one)
                        .centerCrop()
                        .into(binding.oneLayout.oneImage)

                    binding.oneLayout.lockImage.visibility = if (folder.private) View.VISIBLE else View.GONE
                }
            }
        }
    }
}