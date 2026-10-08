package com.pulseworkout.gym_timer

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

@UnstableApi
class MainActivity : FlutterActivity() {
    private var exporter: Transformer? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingOutput: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pulse/video").setMethodCallHandler { call, result ->
            when (call.method) {
                "settings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "export" -> {
                    if (exporter != null) {
                        result.error("BUSY", "A video is already being exported", null)
                    } else {
                        try {
                            val source = requireNotNull(call.argument<String>("source"))
                            val output = File(requireNotNull(call.argument<String>("output")))
                            val plan = requireNotNull(call.argument<Map<String, Any?>>("plan"))
                            require(File(source).isFile && source != output.path)
                            require(!output.exists())
                            val overlay = WorkoutVideoOverlay(plan, call.argument<Map<String, Any?>>("display"))
                            val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(File(source))))
                                .setEffects(Effects(emptyList(), listOf(OverlayEffect(ImmutableList.of<TextureOverlay>(overlay)))))
                                .build()
                            pendingResult = result
                            pendingOutput = output
                            exporter = Transformer.Builder(this)
                                .setVideoMimeType(MimeTypes.VIDEO_H264)
                                .addListener(object : Transformer.Listener {
                                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                                        val reply = pendingResult
                                        clearExport()
                                        reply?.success(null)
                                    }
                                    override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                                        val reply = pendingResult
                                        pendingOutput?.delete()
                                        clearExport()
                                        reply?.error("EXPORT_FAILED", exportException.message, null)
                                    }
                                }).build()
                            exporter!!.start(item, output.path)
                        } catch (error: Exception) {
                            exporter?.cancel()
                            pendingOutput?.delete()
                            clearExport()
                            result.error("EXPORT_FAILED", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun clearExport() {
        exporter = null
        pendingResult = null
        pendingOutput = null
    }

    override fun onDestroy() {
        exporter?.cancel()
        pendingOutput?.delete()
        pendingResult?.error("INTERRUPTED", "Export interrupted; the source recording is retained", null)
        clearExport()
        super.onDestroy()
    }
}
