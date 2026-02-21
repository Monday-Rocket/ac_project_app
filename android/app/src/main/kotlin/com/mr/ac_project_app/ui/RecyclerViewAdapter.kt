package com.mr.ac_project_app.ui

import android.net.Uri
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.RecyclerView.ViewHolder
import com.bumptech.glide.Glide
import com.mr.ac_project_app.R
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType
import com.mr.ac_project_app.utils.getShortText

class RecyclerViewAdapter(private val modelList: ArrayList<FolderModel>, private val onFolderSelected: (Int) -> Unit) :
    RecyclerView.Adapter<ViewHolder>() {

    interface FolderViewHolder {
        fun bind(folderModel: FolderModel)
    }

    inner class NoneFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val oneImageView: ImageView = itemView.findViewById(R.id.oneImage)
        private val lockImageView: ImageView = itemView.findViewById(R.id.lockImage)
        private val textView: TextView = itemView.findViewById(R.id.folder_text)

        override fun bind(folderModel: FolderModel) {

            itemView.setOnClickListener {
                onFolderSelected(bindingAdapterPosition)
            }

            textView.text = getShortText(folderModel.name)

            lockImageView.visibility = View.GONE

            oneImageView.clipToOutline = true

            Glide.with(itemView)
                .load(R.drawable.folder_one)
                .centerCrop()
                .into(oneImageView)
        }
    }

    inner class OneFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val oneImageView: ImageView = itemView.findViewById(R.id.oneImage)
        private val lockImageView: ImageView = itemView.findViewById(R.id.lockImage)
        private val textView: TextView = itemView.findViewById(R.id.folder_text)

        override fun bind(folderModel: FolderModel) {

            itemView.setOnClickListener {
                onFolderSelected(bindingAdapterPosition)
            }

            textView.text = getShortText(folderModel.name)

            lockImageView.visibility = View.GONE

            oneImageView.clipToOutline = true

            try {
                Glide.with(itemView)
                    .load(Uri.parse(folderModel.imageUrl))
                    .centerCrop()
                    .placeholder(R.drawable.folder_one)
                    .into(oneImageView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return when (viewType) {
            FolderType.One.ordinal -> {
                OneFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.one_folder, parent, false)
                )
            }
            else -> {
                NoneFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.one_folder, parent, false)
                )
            }
        }
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val folderViewHolder = holder as FolderViewHolder
        folderViewHolder.bind(modelList[position])
    }

    override fun getItemViewType(position: Int): Int {

        return when (modelList[position].type) {
            FolderType.Triple -> 0
            FolderType.Double -> 1
            FolderType.One -> 2
            else -> -1
        }
    }

    override fun getItemCount(): Int {
        return modelList.size
    }

}
