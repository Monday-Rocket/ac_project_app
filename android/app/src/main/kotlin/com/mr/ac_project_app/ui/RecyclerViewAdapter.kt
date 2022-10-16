package com.mr.ac_project_app.ui

import android.net.Uri
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.RecyclerView.ViewHolder
import com.bumptech.glide.Glide
import com.mr.ac_project_app.R
import com.mr.ac_project_app.model.FolderModel
import com.mr.ac_project_app.model.FolderType

class RecyclerViewAdapter(private val modelList: ArrayList<FolderModel>) :
    RecyclerView.Adapter<ViewHolder>() {


    interface FolderViewHolder {
        fun bind(folderModel: FolderModel)
    }

    inner class OneFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val oneImageView: ImageView = itemView.findViewById(R.id.oneImage)

        init {
            itemView.setOnClickListener {
                // TODO Save folderModel
            }
        }

        override fun bind(folderModel: FolderModel) {
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .into(oneImageView)
        }
    }

    inner class DoubleFolderViewHolder(
        itemView: View
    ) : ViewHolder(itemView), FolderViewHolder {

        private val leftImageView: ImageView = itemView.findViewById(R.id.leftImage)
        private val rightImageView: ImageView = itemView.findViewById(R.id.rightImage)

        init {
            itemView.setOnClickListener {
                // TODO Save folderModel
            }
        }

        override fun bind(folderModel: FolderModel) {
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .into(leftImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[1]))
                .into(rightImageView)
        }
    }

    inner class TripleFolderViewHolder(
        itemView: View,
    ) : ViewHolder(itemView), FolderViewHolder {

        private val leftImageView: ImageView = itemView.findViewById(R.id.leftImage)
        private val rightTopImageView: ImageView = itemView.findViewById(R.id.rightTopImage)
        private val rightBottomImageView: ImageView = itemView.findViewById(R.id.rightBottomImage)

        init {
            itemView.setOnClickListener {
                // TODO Save folderModel
            }
        }

        override fun bind(folderModel: FolderModel) {
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[0]))
                .into(leftImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[1]))
                .into(rightTopImageView)
            Glide.with(itemView)
                .load(Uri.parse(folderModel.imageUrlList[2]))
                .into(rightBottomImageView)
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {

        when (viewType) {
            FolderType.PrivateTriple.ordinal -> {
                return TripleFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.three_private_folder, parent, false)
                )
            }
            FolderType.PublicTriple.ordinal -> {
                return TripleFolderViewHolder(
                    itemView = LayoutInflater.from(parent.context)
                        .inflate(R.layout.three_public_folder, parent, false)
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
                return OneFolderViewHolder(
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

    override fun getItemCount(): Int {
        return modelList.size
    }

}
