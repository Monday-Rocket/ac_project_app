package com.mr.ac_project_app

import android.content.Intent
import android.graphics.Rect
import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mr.ac_project_app.databinding.ActivityShareBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.ui.RecyclerViewAdapter
import com.mr.ac_project_app.utils.toDp


class ShareActivity : ComponentActivity() {

    private var resultData: String = ""
    private lateinit var binding: ActivityShareBinding

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

        binding.folderPlusButton.setOnClickListener {
            val intent = Intent(this@ShareActivity, NewFolderActivity::class.java)
            // TODO intent.putExtra("link", resultData)
            intent.putExtra("link", "https://i.pinimg.com/originals/82/18/c4/8218c49bb19adffbe1704a9a60ec4875.jpg")
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
        val modelList = arrayListOf(
            FolderModel.create(
                listOf("https://upload.wikimedia.org/wikipedia/ko/thumb/4/4a/%EC%8B%A0%EC%A7%B1%EA%B5%AC.png/230px-%EC%8B%A0%EC%A7%B1%EA%B5%AC.png"),
                "짱구",
                false
            ),
            FolderModel.create(
                listOf(
                    "https://upload.wikimedia.org/wikipedia/ko/thumb/4/4a/%EC%8B%A0%EC%A7%B1%EA%B5%AC.png/230px-%EC%8B%A0%EC%A7%B1%EA%B5%AC.png",
                    "https://upload.wikimedia.org/wikipedia/ko/thumb/4/4a/%EC%8B%A0%EC%A7%B1%EA%B5%AC.png/230px-%EC%8B%A0%EC%A7%B1%EA%B5%AC.png",
                ),
                "짱구",
                false
            ),
            FolderModel.create(
                listOf(
                    "https://i.pinimg.com/originals/82/18/c4/8218c49bb19adffbe1704a9a60ec4875.jpg",
                    "https://i.pinimg.com/originals/82/18/c4/8218c49bb19adffbe1704a9a60ec4875.jpg",
                    "https://upload.wikimedia.org/wikipedia/ko/thumb/4/4a/%EC%8B%A0%EC%A7%B1%EA%B5%AC.png/230px-%EC%8B%A0%EC%A7%B1%EA%B5%AC.png"
                ),
                "스타 버터플라이",
                false
            ),
            FolderModel.create(
                listOf("https://upload.wikimedia.org/wikipedia/ko/thumb/4/4a/%EC%8B%A0%EC%A7%B1%EA%B5%AC.png/230px-%EC%8B%A0%EC%A7%B1%EA%B5%AC.png"),
                "짱구",
                false
            ),
            FolderModel.create(
                listOf(),
                "없음",
                false
            )
        )
        binding.folderList.adapter = RecyclerViewAdapter(
            modelList
        ) { position ->
            val intent = Intent(this@ShareActivity, SaveSuccessActivity::class.java)
            intent.putExtra("title", "선택한 폴더에 저장 완료!")
            intent.putExtra("folder", modelList[position])
            startActivity(intent)
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        resultData = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (TextUtils.isEmpty(resultData)) {
            resultData = intent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""
        }
        Toast.makeText(applicationContext, resultData, Toast.LENGTH_SHORT).show()
        Log.i("ACP", "onResume:: $resultData")
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