package com.mr.ac_project_app.ui

import android.os.Build
import android.view.View
import android.view.Window
import android.view.WindowManager
import androidx.core.view.*


class InsetsWithKeyboardCallback(window: Window) : OnApplyWindowInsetsListener,
    WindowInsetsAnimationCompat.Callback(DISPATCH_MODE_CONTINUE_ON_SUBTREE) {

    private var deferredInsets = false
    private var view: View? = null
    private var lastWindowInsets: WindowInsetsCompat? = null

    init {
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // API 29 이하의 디바이스를 위해
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        }
    }

    override fun onApplyWindowInsets(v: View, insets: WindowInsetsCompat): WindowInsetsCompat {
        view = v
        lastWindowInsets = insets
        val types = when {
            // 지연 플래그가 활성화되면 systemBars() 삽입만 사용합니다.
            deferredInsets -> WindowInsetsCompat.Type.systemBars()
            // 지연 플래그가 비활성화되면 systemBars() 및 ime() 삽입의 조합을 사용합니다.
            else -> WindowInsetsCompat.Type.systemBars() + WindowInsetsCompat.Type.ime()
        }

        val typeInsets = insets.getInsets(types)
        v.setPadding(typeInsets.left, typeInsets.top, typeInsets.right, typeInsets.bottom)
        return WindowInsetsCompat.CONSUMED
    }

    override fun onPrepare(animation: WindowInsetsAnimationCompat) {
        if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
            // IME가 표시되지 않으면 WindowInsetsCompat.Type.ime() 삽입을 연기합니다.
            deferredInsets = true
        }
    }

    override fun onProgress(
        insets: WindowInsetsCompat,
        runningAnimations: MutableList<WindowInsetsAnimationCompat>
    ): WindowInsetsCompat {
        return insets
    }

    override fun onEnd(animation: WindowInsetsAnimationCompat) {
        if (deferredInsets && (animation.typeMask and WindowInsetsCompat.Type.ime()) != 0) {
            // IME 애니메이션이 완료되고 IME 삽입이 지연되면 플래그를 재설정합니다.
            deferredInsets = false

            // 일반 디스패치 주기에서 처리하도록 하면 너무 늦게 발생하여 시각적 깜박임이 발생하므로 삽입을 수동으로 디스패치합니다.
            // 따라서 뷰에 가장 최근의 WindowInsets을 보냅니다.
            if (lastWindowInsets != null && view != null) {
                ViewCompat.dispatchApplyWindowInsets(view!!, lastWindowInsets!!)
            }
        }
    }

}