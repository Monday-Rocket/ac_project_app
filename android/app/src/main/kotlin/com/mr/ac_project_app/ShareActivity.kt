package com.mr.ac_project_app

import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.graphics.Rect
import android.os.Bundle
import android.provider.BaseColumns
import android.text.TextUtils
import android.util.Log
import android.view.View
import androidx.activity.ComponentActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mr.ac_project_app.data.ShareContract.LinkTempEntry
import com.mr.ac_project_app.data.ShareContract.FolderTempEntry
import com.mr.ac_project_app.data.ShareContract.LinkEntry
import com.mr.ac_project_app.data.ShareContract.FolderEntry
import com.mr.ac_project_app.data.ShareDbHelper
import com.mr.ac_project_app.databinding.ActivityShareBinding
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import com.mr.ac_project_app.model.SaveType
import com.mr.ac_project_app.ui.RecyclerViewAdapter
import com.mr.ac_project_app.utils.toDp


class ShareActivity : ComponentActivity() {

    private var savedLink: String = ""
    private var isLinkSaved = false
    private lateinit var binding: ActivityShareBinding
    private var dbHelper: ShareDbHelper? = null
    private val modelList = arrayListOf<FolderModel>()

    companion object {
        const val SHARED_PREF = "share_pref"
        const val SHARE_LIST_ID = "sharedDataList"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityShareBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dbHelper = ShareDbHelper(applicationContext)

        binding.background.setOnClickListener {
            finishAffinity()
        }

        binding.closeButton.setOnClickListener {
            finishAffinity()
        }

        binding.folderPlusButton.setOnClickListener {
            val intent = Intent(this@ShareActivity, NewFolderActivity::class.java)
            intent.putExtra("link", savedLink)
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
        modelList.addAll(getFoldersFromDB())
        binding.folderList.adapter = RecyclerViewAdapter(
            modelList
        ) { position ->
            val intent = Intent(this@ShareActivity, SaveSuccessActivity::class.java)
            intent.putExtra("folder", modelList[position])
            intent.putExtra("saveType", SaveType.Selected)
            startActivity(intent)
            overridePendingTransition(R.anim.slide_right_enter, R.anim.slide_right_exit)
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        savedLink = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (TextUtils.isEmpty(savedLink)) {
            savedLink = intent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""
        }
        Log.i("ACP", "onResume:: $savedLink")
        if (!isLinkSaved && !TextUtils.isEmpty(savedLink)) {
            saveLinkWithoutFolder()
            isLinkSaved = true
        }
    }

    private fun saveLinkWithoutFolder() {
        if (dbHelper != null) {
            val db = dbHelper!!.writableDatabase
            val values = ContentValues().apply {
                put(LinkTempEntry.link, savedLink)
            }
            db.insert(LinkTempEntry.table, LinkTempEntry.link, values)
            db.close()
        }
    }

    private fun getFoldersFromDB(): MutableList<FolderModel> {
        if (dbHelper != null) {
            val db = dbHelper!!.readableDatabase
            val folderTempColumns =
                arrayOf(FolderTempEntry.seq, FolderTempEntry.folderName, FolderTempEntry.visible)
            val folderColumns =
                arrayOf(FolderEntry.seq, FolderEntry.folderName, FolderEntry.visible)
            val folderTempCursor =
                db.query(FolderTempEntry.table, folderTempColumns, null, null, null, null, null)
            val folderCursor =
                db.query(FolderEntry.table, folderColumns, null, null, null, null, null)

            val linkColumns = arrayOf(LinkTempEntry.imageLink)

            val folders = mutableListOf<FolderModel>()
            folders.addAll(
                getFolderImage(
                    folderTempCursor,
                    db,
                    FolderTempEntry.folderName,
                    FolderTempEntry.visible,
                    linkColumns
                )
            )
            folders.addAll(
                getFolderImage(
                    folderCursor,
                    db,
                    FolderEntry.folderName,
                    FolderEntry.visible,
                    linkColumns
                )
            )
            db.close()
            return folders
        } else {
            return mutableListOf()
        }
    }

    private fun getFolderImage(
        folderCursor: Cursor,
        db: SQLiteDatabase,
        folderNameColumn: String,
        visibleColumn: String,
        linkColumns: Array<String>,
    ): MutableList<FolderModel> {
        val folders = mutableListOf<FolderModel>()
        with(folderCursor) {
            while (moveToNext()) {
                val id = getLong(getColumnIndexOrThrow(BaseColumns._ID))
                val folderName = getString(getColumnIndexOrThrow(folderNameColumn))
                val visible = getInt(getColumnIndexOrThrow(visibleColumn)) == 1

                val linkTempCursor =
                    getImageLinks(db, LinkTempEntry.table, linkColumns, LinkTempEntry.folderSeq, id)
                val linkCursor =
                    getImageLinks(db, LinkEntry.table, linkColumns, LinkEntry.folderSeq, id)

                val imageLinks = mutableListOf<String>()
                imageLinks.addAll(addImageLinks(linkTempCursor, LinkTempEntry.imageLink))
                imageLinks.addAll(addImageLinks(linkCursor, LinkEntry.imageLink))

                when (imageLinks.size) {
                    1 -> {
                        folders.add(FolderModel(FolderType.One, imageLinks, folderName, visible))
                    }
                    2 -> {
                        folders.add(FolderModel(FolderType.Double, imageLinks, folderName, visible))
                    }
                    3 -> {
                        folders.add(FolderModel(FolderType.Triple, imageLinks, folderName, visible))
                    }
                    else -> {
                        folders.add(FolderModel(FolderType.None, imageLinks, folderName, visible))
                    }
                }
            }
        }
        folderCursor.close()
        return folders
    }

    private fun addImageLinks(
        linkTempCursor: Cursor,
        imageLink: String
    ): MutableList<String> {
        val imageLinks = mutableListOf<String>()
        with(linkTempCursor) {
            while (moveToNext()) {
                imageLinks.add(getString(getColumnIndexOrThrow(imageLink)))
            }
        }
        linkTempCursor.close()
        return imageLinks
    }

    private fun getImageLinks(
        db: SQLiteDatabase,
        table: String,
        linkColumns: Array<String>,
        folderSeq: String,
        id: Long
    ) = db.query(
        table,
        linkColumns,
        "$folderSeq = ?",
        arrayOf("$id"),
        null,
        null,
        null,
        "3"
    )

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