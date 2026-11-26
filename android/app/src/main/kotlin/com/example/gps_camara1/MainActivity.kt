package com.jera.gps_camera

import android.content.ContentValues
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jera.gps_camera/storage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getVideoDimensions" -> {
                    val videoPath = call.argument<String>("videoPath")
                    if (videoPath == null) {
                        result.error("INVALID_ARGUMENT", "videoPath must not be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val retriever = MediaMetadataRetriever()
                        retriever.setDataSource(videoPath)
                        val rawWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1080
                        val rawHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1920
                        val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                        retriever.release()

                        val actualWidth: Int
                        val actualHeight: Int
                        if (rotation == 90 || rotation == 270) {
                            actualWidth = rawHeight
                            actualHeight = rawWidth
                        } else {
                            actualWidth = rawWidth
                            actualHeight = rawHeight
                        }

                        result.success(mapOf("width" to actualWidth, "height" to actualHeight, "rotation" to rotation))
                    } catch (e: Exception) {
                        result.success(mapOf("width" to 1080, "height" to 1920, "rotation" to 0))
                    }
                }
                "saveToDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName") ?: "GPS_MEDIA_${System.currentTimeMillis()}.jpg"
                    val isVideo = call.argument<Boolean>("isVideo") ?: false

                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath must not be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = saveMediaToDownloads(filePath, fileName, isVideo)
                        if (savedPath != null) {
                            result.success(savedPath)
                        } else {
                            result.error("SAVE_FAILED", "Failed to save file to Downloads", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXCEPTION", e.localizedMessage, e.toString())
                    }
                }
                "overlayVideoWatermark" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val overlayPngPath = call.argument<String>("overlayPngPath")
                    val outputPath = call.argument<String>("outputPath")

                    if (videoPath == null || overlayPngPath == null || outputPath == null) {
                        result.error("INVALID_ARGUMENT", "videoPath, overlayPngPath, and outputPath are required", null)
                        return@setMethodCallHandler
                    }

                    overlayWatermark(videoPath, overlayPngPath, outputPath, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    @OptIn(UnstableApi::class)
    private fun overlayWatermark(
        videoPath: String,
        overlayPngPath: String,
        outputPath: String,
        result: MethodChannel.Result
    ) {
        val videoFile = File(videoPath)
        val overlayFile = File(overlayPngPath)
        val outputFile = File(outputPath)

        if (!videoFile.exists() || !overlayFile.exists()) {
            result.error("FILE_NOT_FOUND", "Source video or overlay PNG file does not exist", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeFile(overlayFile.absolutePath)
            if (bitmap == null) {
                result.error("DECODE_ERROR", "Could not decode overlay bitmap", null)
                return
            }

            // Create full-frame static bitmap overlay
            val bitmapOverlay = BitmapOverlay.createStaticBitmapOverlay(bitmap)
            val overlayEffect = OverlayEffect(listOf(bitmapOverlay))
            val effects = Effects(emptyList(), listOf(overlayEffect))

            val mediaItem = MediaItem.fromUri(Uri.fromFile(videoFile))
            val editedMediaItem = EditedMediaItem.Builder(mediaItem)
                .setEffects(effects)
                .build()

            val transformer = Transformer.Builder(context)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        runOnUiThread {
                            result.success(outputFile.absolutePath)
                        }
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exportException: ExportException
                    ) {
                        runOnUiThread {
                            // On error, gracefully fallback to source video so the user never loses footage
                            result.success(videoFile.absolutePath)
                        }
                    }
                })
                .build()

            transformer.start(editedMediaItem, outputFile.absolutePath)
        } catch (t: Throwable) {
            // Fallback to original video on any error
            result.success(videoFile.absolutePath)
        }
    }

    private fun saveMediaToDownloads(sourceFilePath: String, fileName: String, isVideo: Boolean): String? {
        val sourceFile = File(sourceFilePath)
        if (!sourceFile.exists()) {
            return null
        }

        val mimeType = if (isVideo) "video/mp4" else "image/jpeg"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+): Scoped Storage via MediaStore.Downloads (No extra permissions required)
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/GPS Camera")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)

            if (uri != null) {
                try {
                    resolver.openOutputStream(uri)?.use { outputStream ->
                        FileInputStream(sourceFile).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }

                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)

                    uri.toString()
                } catch (e: Exception) {
                    resolver.delete(uri, null, null)
                    throw e
                }
            } else {
                null
            }
        } else {
            // Android 9 and lower: Direct file copy to public Downloads directory
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val appDir = File(downloadsDir, "GPS Camera")
            if (!appDir.exists()) {
                appDir.mkdirs()
            }

            val destFile = File(appDir, fileName)
            sourceFile.copyTo(destFile, overwrite = true)

            // Trigger MediaScanner so the media appears in Gallery & Downloads immediately
            MediaScannerConnection.scanFile(
                context,
                arrayOf(destFile.absolutePath),
                arrayOf(mimeType),
                null
            )

            destFile.absolutePath
        }
    }
}
