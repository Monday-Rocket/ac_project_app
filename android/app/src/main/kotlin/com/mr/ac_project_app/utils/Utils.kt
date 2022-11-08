package com.mr.ac_project_app.utils

import android.content.Context
import android.util.DisplayMetrics
import org.json.JSONObject
import org.threeten.bp.LocalDateTime
import org.threeten.bp.format.DateTimeFormatter

fun toDp(dp: Float, context: Context): Float {
    return dp * (context.resources
        .displayMetrics.densityDpi.toFloat() / DisplayMetrics.DENSITY_DEFAULT)
}

fun JSONObject.convert(): String {
    return this.toString().replace("\\", "")
}

fun getCurrentDateTime(): String? {
    return LocalDateTime.now().format(DateTimeFormatter.ISO_INSTANT)
}