package com.mr.ac_project_app.dialog

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.Window
import androidx.fragment.app.DialogFragment
import com.mr.ac_project_app.databinding.ShareDialogBinding

class MessageDialog(
    private val confirmDialogInterface: ConfirmDialogInterface,
    private val imageId: Int?,
    private val title: String,
    private val buttonText: String,
    private val content: String,
    private val mustFinished: Boolean? = false,
): DialogFragment() {

    private var _binding: ShareDialogBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = ShareDialogBinding.inflate(inflater, container, false)

        dialog?.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        dialog?.window?.requestFeature(Window.FEATURE_NO_TITLE)

        binding.dialogTitleText.text = title
        binding.dialogContentText.text = content
        if (imageId != null) {
            binding.folderIcon.setImageResource(imageId)
            binding.dialogCloseButton.setOnClickListener {
                dismiss()
            }
        } else {
            binding.dialogCloseButton.setOnClickListener {
                this.confirmDialogInterface.onButtonClick()
                dismiss()
            }
        }

        binding.dialogOneButton.text = buttonText

        binding.dialogOneButton.setOnClickListener {
            this.confirmDialogInterface.onButtonClick()
            dismiss()
        }


        return binding.root
    }

    override fun onDestroy() {
        super.onDestroy()
        if (mustFinished == true) {
            this.confirmDialogInterface.onButtonClick()
        }
    }
}

interface ConfirmDialogInterface {
    fun onButtonClick()
}
