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

class RecyclerViewAdapter(private val modelList: ArrayList<FolderModel>, private val onFolderSelected: (Int) -> Unit) :
    RecyclerView.Adapter<ViewHolder>() {

    interface FolderViewHolder {
        fun bind(folderModel: FolderModel)
    }

    inner class NoneFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val oneImageView: ImageView = itemView.findViewById(R.id.oneImage)
        private val textView: TextView = itemView.findViewById(R.id.folder_text)

        override fun bind(folderModel: FolderModel) {

            itemView.setOnClickListener {
                // TODO Save folderModel
            }

            textView.text = folderModel.name

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

            textView.text = folderModel.name

            if (folderModel.private) {
                lockImageView.visibility = View.VISIBLE
            } else {
                lockImageView.visibility = View.GONE
            }

            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .centerCrop()
                .placeholder(R.drawable.folder_one)
                .into(oneImageView)
        }
    }

    inner class DoubleFolderViewHolder(
        itemView: View
    ) : ViewHolder(itemView), FolderViewHolder {

        private val leftImageView: ImageView = itemView.findViewById(R.id.leftImage)
        private val rightImageView: ImageView = itemView.findViewById(R.id.rightImage)
        private val lockImageView: ImageView = itemView.findViewById(R.id.lockImage)
        private val textView: TextView = itemView.findViewById(R.id.folder_text)

        override fun bind(folderModel: FolderModel) {

            itemView.setOnClickListener {
                onFolderSelected(bindingAdapterPosition)
            }

            textView.text = folderModel.name

            if (folderModel.private) {
                lockImageView.visibility = View.VISIBLE
            } else {
                lockImageView.visibility = View.GONE
            }

            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .centerCrop()
                .placeholder(R.drawable.folder_left)
                .into(leftImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[1]))
                .centerCrop()
                .placeholder(R.drawable.folder_right)
                .into(rightImageView)
        }
    }

    inner class TripleFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val leftImageView: ImageView = itemView.findViewById(R.id.leftImage)
        private val rightTopImageView: ImageView = itemView.findViewById(R.id.rightTopImage)
        private val rightBottomImageView: ImageView = itemView.findViewById(R.id.rightBottomImage)
        private val lockImageView: ImageView = itemView.findViewById(R.id.lockImage)
        private val textView: TextView = itemView.findViewById(R.id.folder_text)

        override fun bind(folderModel: FolderModel) {

            itemView.setOnClickListener {
                onFolderSelected(bindingAdapterPosition)
            }

            textView.text = folderModel.name

            if (folderModel.private) {
                lockImageView.visibility = View.VISIBLE
            } else {
                lockImageView.visibility = View.GONE
            }

            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .centerCrop()
                .placeholder(R.drawable.folder_left)
                .into(leftImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[1]))
                .centerCrop()
                .placeholder(R.drawable.folder_right_top)
                .into(rightTopImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[2]))
                .centerCrop()
                .placeholder(R.drawable.folder_right_bottom)
                .into(rightBottomImageView)
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {

        when (viewType) {
            FolderType.Triple.ordinal -> {
                return TripleFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.triple_folder, parent, false)
                )
            }
            FolderType.Double.ordinal -> {
                return DoubleFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.double_folder, parent, false)
                )
            }
            FolderType.One.ordinal -> {
                return OneFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.one_folder, parent, false)
                )
            }
            else -> {
                return NoneFolderViewHolder(
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
