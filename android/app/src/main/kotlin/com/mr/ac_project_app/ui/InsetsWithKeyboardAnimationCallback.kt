package com.mr.ac_project_app.ui

import android.view.View
import androidx.core.graphics.Insets
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat

class InsetsWithKeyboardAnimationCallback(private val view: View) :
    WindowInsetsAnimationCompat.Callback(DISPATCH_MODE_STOP) {

    override fun onProgress(
        insets: WindowInsetsCompat,
        runningAnimations: MutableList<WindowInsetsAnimationCompat>
    ): WindowInsetsCompat {
        val imeInsets = insets.getInsets(WindowInsetsCompat.Type.ime())
        val systemInsets = insets.getInsets(WindowInsetsCompat.Type.systemBars())


        val diff = Insets.subtract(imeInsets, systemInsets).let {
            Insets.max(it, Insets.NONE)
        }

        view.translationX = (diff.left - diff.right).toFloat()
        view.translationY = (diff.top - diff.bottom).toFloat()

        return insets
    }

    override fun onEnd(animation: WindowInsetsAnimationCompat) {
        // 애니메이션이 완료된 후 translation 값을 재설정합니다.
        view.translationX = 0f
        view.translationY = 0f
    }
}