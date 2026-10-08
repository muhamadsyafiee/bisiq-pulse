package com.pulseworkout.gym_timer

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import androidx.media3.common.OverlaySettings
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.StaticOverlaySettings
import kotlin.math.max

/** Independent of the movable timer: free exports always carry a visible mark. */
@UnstableApi
class PulseWatermarkOverlay : BitmapOverlay() {
    private var bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
    private val settings = StaticOverlaySettings.Builder()
        .setBackgroundFrameAnchor(.95f, .96f).setOverlayFrameAnchor(1f, 1f).build()
    override fun configure(videoSize: Size) {
        super.configure(videoSize)
        bitmap.recycle()
        val width = max(96, (videoSize.width * .18f).toInt())
        bitmap = Bitmap.createBitmap(width, (width * .4f).toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.argb(170, 0, 0, 0)
        canvas.drawRoundRect(0f, 0f, width.toFloat(), bitmap.height.toFloat(), 8f, 8f, paint)
        paint.color = Color.WHITE
        paint.typeface = Typeface.create("sans-serif", Typeface.BOLD)
        paint.textSize = width * .22f
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText("PULSE", width / 2f, bitmap.height / 2f - (paint.ascent() + paint.descent()) / 2f, paint)
    }
    override fun getBitmap(presentationTimeUs: Long): Bitmap = bitmap
    override fun getOverlaySettings(presentationTimeUs: Long): OverlaySettings = settings
    override fun release() { super.release(); bitmap.recycle() }
}
