package com.mr.ac_project_app.utils

import android.content.Context
import android.util.DisplayMetrics

fun toDp(dp: Float, context: Context): Float {
    return dp * (context.resources
        .displayMetrics.densityDpi.toFloat() / DisplayMetrics.DENSITY_DEFAULT)
}
