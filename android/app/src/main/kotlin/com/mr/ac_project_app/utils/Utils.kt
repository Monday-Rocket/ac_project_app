package com.mr.ac_project_app.utils

import android.content.Context
import android.util.DisplayMetrics
import org.json.JSONObject

fun toDp(dp: Float, context: Context): Float {
    return dp * (context.resources
        .displayMetrics.densityDpi.toFloat() / DisplayMetrics.DENSITY_DEFAULT)
}

fun JSONObject.convert(): String {
    return this.toString().replace("\\", "")
}