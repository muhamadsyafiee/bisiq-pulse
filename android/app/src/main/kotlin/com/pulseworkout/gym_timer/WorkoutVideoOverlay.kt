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
import kotlin.math.ceil
import kotlin.math.max

/** Draws from video timestamps rather than wall time, so encoding speed does
 * not affect the workout countdown. Camera mode records one continuous take. */
@UnstableApi
class WorkoutVideoOverlay(plan: Map<String, Any?>) : BitmapOverlay() {
    private data class Exercise(val name: String, val work: Int, val rest: Int)
    private data class Frame(val index: Int, val rest: Boolean, val seconds: Int, val progress: Float, val finished: Boolean = false)
    private val title = plan["name"] as String
    private val exercises = (plan["exercises"] as List<*>).map {
        val item = it as Map<*, *>
        Exercise(item["name"] as String, (item["workoutSeconds"] as Number).toInt(), (item["restSeconds"] as Number).toInt())
    }
    private var bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var lastKey = ""
    private val settings = StaticOverlaySettings.Builder()
        .setBackgroundFrameAnchor(0f, -0.85f)
        .setOverlayFrameAnchor(0f, -1f).build()

    init { require(exercises.isNotEmpty() && exercises.all { it.work > 0 && it.rest >= 0 }) }

    override fun configure(videoSize: Size) {
        super.configure(videoSize)
        bitmap.recycle()
        val width = max(240, (videoSize.width * .90f).toInt())
        bitmap = Bitmap.createBitmap(width, (width * .43f).toInt(), Bitmap.Config.ARGB_8888)
        lastKey = ""
    }

    private fun frameAt(timeUs: Long): Frame {
        var seconds = max(0.0, timeUs / 1_000_000.0)
        for ((index, exercise) in exercises.withIndex()) {
            if (seconds < exercise.work) return Frame(index, false, ceil(exercise.work - seconds).toInt(), ((exercise.work - seconds) / exercise.work).toFloat())
            seconds -= exercise.work
            if (index < exercises.lastIndex && exercise.rest > 0) {
                if (seconds < exercise.rest) return Frame(index, true, ceil(exercise.rest - seconds).toInt(), ((exercise.rest - seconds) / exercise.rest).toFloat())
                seconds -= exercise.rest
            }
        }
        return Frame(exercises.lastIndex, false, 0, 0f, true)
    }

    override fun getBitmap(presentationTimeUs: Long): Bitmap {
        val frame = frameAt(presentationTimeUs)
        val key = "${frame.index}-${frame.rest}-${frame.seconds}-${frame.finished}"
        if (key == lastKey) return bitmap
        lastKey = key
        bitmap.eraseColor(Color.TRANSPARENT)
        val canvas = Canvas(bitmap)
        val w = bitmap.width.toFloat()
        val h = bitmap.height.toFloat()
        val accent = Color.parseColor(if (frame.rest) "#FFC16E" else "#B6F36A")
        paint.color = Color.argb(218, 16, 20, 18)
        canvas.drawRoundRect(0f, 0f, w, h, w * .025f, w * .025f, paint)
        fun text(value: String, x: Float, y: Float, size: Float, color: Int, maxWidth: Float) {
            paint.color = color
            paint.typeface = Typeface.create("sans-serif", Typeface.BOLD)
            paint.textSize = size
            var visible = value.replace('\n', ' ')
            if (paint.measureText(visible) > maxWidth) {
                while (visible.isNotEmpty() && paint.measureText("$visible…") > maxWidth) visible = visible.dropLast(1)
                visible += "…"
            }
            canvas.drawText(visible, x, y, paint)
        }
        val pad = w * .045f
        text("PULSE  •  $title", pad, w * .065f, w * .032f, Color.LTGRAY, w - pad * 2)
        val phase = if (frame.finished) "SELESAI" else if (frame.rest) "REHAT" else "SENAMAN"
        text("$phase  •  GERAKAN ${frame.index + 1}/${exercises.size}", pad, w * .125f, w * .030f, accent, w - pad * 2)
        text(if (frame.finished) "Workout Finished" else if (frame.rest) "Tarik nafas seketika." else exercises[frame.index].name, pad, w * .20f, w * .055f, Color.WHITE, w - pad * 2)
        val time = "${frame.seconds / 60}:${(frame.seconds % 60).toString().padStart(2, '0')}"
        text(time, pad, w * .34f, w * .125f, accent, w * .64f)
        text("SAAT", w * .71f, w * .31f, w * .032f, Color.LTGRAY, w * .24f)
        val next = exercises.getOrNull(frame.index + 1)?.name ?: "Selesai"
        text("Seterusnya: $next", pad, w * .395f, w * .029f, Color.LTGRAY, w - pad * 2)
        paint.color = accent
        canvas.drawRect(pad, h - w * .013f, pad + (w - pad * 2) * frame.progress.coerceIn(0f, 1f), h - w * .008f, paint)
        return bitmap
    }

    override fun getOverlaySettings(presentationTimeUs: Long): OverlaySettings = settings
    override fun release() { super.release(); bitmap.recycle() }
}
