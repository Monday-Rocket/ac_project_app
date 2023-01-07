package com.mr.ac_project_app.utils

import android.content.Context
import android.util.DisplayMetrics
import android.util.Log
import com.mr.ac_project_app.LinkPoolApp
import org.apache.commons.codec.binary.Base64
import org.json.JSONObject
import org.threeten.bp.LocalDateTime
import org.threeten.bp.ZoneId
import org.threeten.bp.ZonedDateTime
import org.threeten.bp.format.DateTimeFormatter


fun toDp(dp: Float, context: Context): Float {
    return dp * (context.resources
        .displayMetrics.densityDpi.toFloat() / DisplayMetrics.DENSITY_DEFAULT)
}

fun JSONObject.convert(): String {
    return this.toString().replace("\\", "")
}

fun getCurrentDateTime(): String {
    val now = ZonedDateTime.of(LocalDateTime.now(ZoneId.of("UTC")), ZoneId.of("UTC"))
    val time = now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")).plus("Z")
    Log.i(LinkPoolApp.TAG, time)
    return time
}

fun getShortText(folderName: String): String {
    val short = if (folderName.length > 7) {
        folderName.substring(0, 7) + "..."
    } else {
        folderName
    }
    return short
}


fun encodeBase64(text: String): String {
    return String(Base64.encodeBase64(text.toByteArray(Charsets.UTF_8)))
}