package com.mr.ac_project_app.view.share

import android.content.Intent
import android.graphics.Rect
import android.net.UrlQuerySanitizer
import android.os.Bundle
import android.text.TextUtils
import android.text.method.ScrollingMovementMethod
import android.view.View
import androidx.activity.viewModels
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mr.ac_project_app.R
import com.mr.ac_project_app.databinding.ActivityShareBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.ui.RecyclerViewAdapter
import com.mr.ac_project_app.utils.toDp
import com.mr.ac_project_app.view.LinkErrorActivity
import com.mr.ac_project_app.view.SaveSuccessActivity
import com.mr.ac_project_app.view.folder.NewFolderActivity
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLDecoder


class ShareActivity : FragmentActivity() {

    private lateinit var binding: ActivityShareBinding
    private val viewModel: ShareViewModel by viewModels()
    private val modelList = arrayListOf<FolderModel>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityShareBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.background.setOnClickListener {
            finishAffinity()
        }

        binding.closeButton.setOnClickListener {
            finishAffinity()
        }

        binding.folderPlusButton.setOnClickListener {
            val intent = Intent(this@ShareActivity, NewFolderActivity::class.java)
            intent.putExtra("link", viewModel.savedLink.value)
            intent.putExtra("imageLink", viewModel.imageLink.value)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
            finish()
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
        }

        binding.folderList.addItemDecoration(
            HorizontalSpaceItemDecoration(
                toDp(
                    12f,
                    applicationContext
                ).toInt()
            )
        )
        binding.folderList.layoutManager = LinearLayoutManager(this, RecyclerView.HORIZONTAL, false)
        val folders = viewModel.getFoldersFromDB()
        modelList.addAll(folders)

        binding.folderList.adapter = RecyclerViewAdapter(
            modelList
        ) { position ->

            val folder = modelList[position].changeImageUrl(viewModel.imageLink.value ?: "")
            viewModel.saveLinkWithFolder(folder)

            val intent = Intent(this@ShareActivity, SaveSuccessActivity::class.java)
            intent.putExtra("folder", folder)
            intent.putExtra("link", viewModel.savedLink.value)
            intent.putExtra("saveType", SaveType.Selected)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
            finish()
        }

        if (folders.isEmpty()) {
            binding.emptyFolderImage.root.visibility = View.VISIBLE
            binding.emptyFolderImage.root.setOnClickListener {
                binding.folderPlusButton.callOnClick()
            }
        } else {
            binding.emptyFolderImage.root.visibility = View.GONE
        }

        binding.noticeDescriptionText.movementMethod = ScrollingMovementMethod()
    }

    override fun onResume() {
        super.onResume()
        var originLink = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (TextUtils.isEmpty(originLink)) {
            originLink = intent.getStringExtra("android.intent.extra.PROCESS_TEXT")
                ?: ""
        }

        if (TextUtils.isEmpty(originLink)) {
            showErrorActivity()
        } else {
            CoroutineScope(Dispatchers.IO).launch {
                val huc = withContext(Dispatchers.IO) {
                    URL(originLink).openConnection()
                } as HttpURLConnection
                huc.requestMethod = "GET"

                if (huc.responseCode == HttpURLConnection.HTTP_OK) {
                    var link = huc.url.toString()
                    if (link.contains("%")) {
                        link = withContext(Dispatchers.IO) {
                            URLDecoder.decode(link, "UTF-8")
                        }
                    }
                    val queryUrl = huc.url.query
                    if (queryUrl != null && queryUrl.contains("url")) {
                        val sanitizer = UrlQuerySanitizer(link)

                        for (item in sanitizer.parameterList) {
                            if (item.mParameter.equals("url")) {
                                link = item.mValue
                                break
                            }
                        }
                    }

                    val hasError = viewModel.saveLink(link, originLink)
                    if (hasError) {
                        showErrorActivity()
                    }
                }
            }
        }
    }

    private fun showErrorActivity() {
        val intent = Intent(this@ShareActivity, LinkErrorActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(intent)
        finish()
    }

    inner class HorizontalSpaceItemDecoration(private val space: Int) :
        RecyclerView.ItemDecoration() {

        override fun getItemOffsets(
            outRect: Rect, view: View, parent: RecyclerView,
            state: RecyclerView.State
        ) {
            outRect.right = space
        }
    }
}