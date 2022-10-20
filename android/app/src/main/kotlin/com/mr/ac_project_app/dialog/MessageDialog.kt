package com.mr.ac_project_app.dialog

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.DialogFragment
import com.mr.ac_project_app.databinding.ShareDialogBinding

class MessageDialog(
    confirmDialogInterface: ConfirmDialogInterface,
    imageId: Int,
    title: String,
    content: String,
): DialogFragment() {

    private var _binding: ShareDialogBinding? = null
    private val binding get() = _binding!!

    private var confirmDialogInterface: ConfirmDialogInterface? = null

    private var title: String? = null
    private var content: String? = null
    private var imageId: Int? = null

    init {
        this.title = title
        this.content = content
        this.imageId = imageId
        this.confirmDialogInterface = confirmDialogInterface
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = ShareDialogBinding.inflate(inflater, container, false)
        val view = binding.root

        binding.dialogTitleText.text = title
        binding.dialogContentText.text = content
        if (imageId != null) {
            binding.folderIcon.setImageResource(imageId!!)
        }

        binding.dialogOneButton.setOnClickListener {
            this.confirmDialogInterface?.onButtonClick()
            dismiss()
        }

        return view
    }
}

interface ConfirmDialogInterface {
    fun onButtonClick()
}
