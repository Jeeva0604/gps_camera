package com.jera.gps_camera

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
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
            if (call.method == "saveToDownloads") {
                val filePath = call.argument<String>("filePath")
                val fileName = call.argument<String>("fileName") ?: "GPS_PHOTO_${System.currentTimeMillis()}.jpg"

                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath must not be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val savedPath = saveImageToDownloads(filePath, fileName)
                    if (savedPath != null) {
                        result.success(savedPath)
                    } else {
                        result.error("SAVE_FAILED", "Failed to save image to Downloads", null)
                    }
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.localizedMessage, e.toString())
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToDownloads(sourceFilePath: String, fileName: String): String? {
        val sourceFile = File(sourceFilePath)
        if (!sourceFile.exists()) {
            return null
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+): Scoped Storage via MediaStore.Downloads (No extra permissions required)
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "image/jpeg")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/GPS Camera")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri: Uri? = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)

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

            // Trigger MediaScanner so the photo appears in Gallery & Downloads immediately
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(destFile.absolutePath),
                arrayOf("image/jpeg"),
                null
            )

            destFile.absolutePath
        }
    }
}
