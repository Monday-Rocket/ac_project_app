package com.mr.ac_project_app.dialog

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.DialogFragment
import com.mr.ac_project_app.databinding.ShareDialogBinding

class MessageDialog(
    private val confirmDialogInterface: ConfirmDialogInterface,
    private val imageId: Int?,
    private val title: String,
    private val buttonText: String,
    private val content: String,
): DialogFragment() {

    private var _binding: ShareDialogBinding? = null
    private val binding get() = _binding!!

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
            binding.folderIcon.setImageResource(imageId)
            binding.dialogCloseButton.setOnClickListener {
                dismiss()
            }
        } else {
            binding.dialogCloseButton.setOnClickListener {
                this.confirmDialogInterface.onButtonClose()
                dismiss()
            }
        }

        binding.dialogOneButton.text = buttonText

        binding.dialogOneButton.setOnClickListener {
            this.confirmDialogInterface.onButtonClick()
            dismiss()
        }


        return view
    }
}

interface ConfirmDialogInterface {
    fun onButtonClick()
    fun onButtonClose()
}
