package com.mr.ac_project_app.view.share

import android.content.Intent
import android.graphics.Rect
import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.view.View
import androidx.activity.ComponentActivity
import androidx.activity.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mr.ac_project_app.view.folder.NewFolderActivity
import com.mr.ac_project_app.R
import com.mr.ac_project_app.databinding.ActivityShareBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.ui.RecyclerViewAdapter
import com.mr.ac_project_app.utils.toDp
import com.mr.ac_project_app.view.SaveSuccessActivity


class ShareActivity : ComponentActivity() {

    private var linkSeq: Long? = null
    private var savedLink: String = ""
    private var isLinkSaved = false
    private lateinit var binding: ActivityShareBinding
    private val modelList = arrayListOf<FolderModel>()

    private val viewModel: ShareViewModel by viewModels()

    companion object {
        const val SHARED_PREF = "share_pref"
        const val SHARE_LIST_ID = "sharedDataList"
    }

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
            intent.putExtra("link", savedLink)
            intent.putExtra("linkSeq", linkSeq)
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

        binding.folderList.adapter = RecyclerViewAdapter(
            modelList
        ) { position ->

            val folder = modelList[position]

            viewModel.saveLinkWithFolder(folder, linkSeq)

            val intent = Intent(this@ShareActivity, SaveSuccessActivity::class.java)
            intent.putExtra("folder", modelList[position])
            intent.putExtra("saveType", SaveType.Selected)
            intent.putExtra("linkSeq", linkSeq)
            startActivity(intent)
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
            finish()
        }

        modelList.addAll(viewModel.getFoldersFromDB())
    }

    override fun onResume() {
        super.onResume()
        savedLink = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (TextUtils.isEmpty(savedLink)) {
            savedLink = intent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""
        }
        Log.i("ACP", "onResume:: $savedLink")
        if (!isLinkSaved && !TextUtils.isEmpty(savedLink)) {
            linkSeq = viewModel.saveLinkWithoutFolder(savedLink)
            isLinkSaved = true
        }
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