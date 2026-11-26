import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const MethodChannel _channel =
      MethodChannel('com.jera.gps_camera/storage');

  /// Saves the stamped image bytes to a temporary file for fast previewing & sharing.
  static Future<File> saveToTempFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final filename = 'GPS_PHOTO_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(imageBytes, flush: true);
    return file;
  }

  /// Backward-compatible alias for saveToDownloads
  static Future<bool> saveToGallery(File file, {bool isVideo = false}) async {
    return saveToDownloads(file, isVideo: isVideo);
  }

  /// Gets the real width, height, and orientation of the recorded video file.
  static Future<Map<String, int>> getVideoDimensions(String videoPath) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final Map? res = await _channel.invokeMethod<Map>(
          'getVideoDimensions',
          {'videoPath': videoPath},
        );
        if (res != null) {
          return {
            'width': (res['width'] as num?)?.toInt() ?? 1080,
            'height': (res['height'] as num?)?.toInt() ?? 1920,
            'rotation': (res['rotation'] as num?)?.toInt() ?? 0,
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting video dimensions: $e');
    }
    return {'width': 1080, 'height': 1920, 'rotation': 0};
  }

  /// Burns the rendered GPS location watermark card PNG onto a video using native Media3 Transformer.
  static Future<File?> overlayWatermarkOnVideo({
    required String videoPath,
    required String overlayPngPath,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/STAMPED_VIDEO_${DateTime.now().millisecondsSinceEpoch}.mp4';

      if (defaultTargetPlatform == TargetPlatform.android) {
        final String? result = await _channel.invokeMethod<String>(
          'overlayVideoWatermark',
          {
            'videoPath': videoPath,
            'overlayPngPath': overlayPngPath,
            'outputPath': outputPath,
          },
        );

        if (result != null && await File(result).exists()) {
          return File(result);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error overlaying watermark on video: $e');
      return null;
    }
  }

  /// Saves the stamped image or recorded video file directly to the device's Downloads directory.
  /// On Android, uses native Kotlin MediaStore.Downloads API (requires zero dangerous permissions).
  /// On iOS, saves to the app's accessible Documents/Downloads directory.
  static Future<bool> saveToDownloads(File file, {bool isVideo = false}) async {
    try {
      if (!await file.exists()) return false;

      final extension = isVideo ? 'mp4' : 'jpg';
      final prefix = isVideo ? 'GPS_VIDEO_' : 'GPS_PHOTO_';
      final filename = '$prefix${DateTime.now().millisecondsSinceEpoch}.$extension';

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Native Android Kotlin call to MediaStore.Downloads
        final String? result = await _channel.invokeMethod<String>(
          'saveToDownloads',
          {
            'filePath': file.path,
            'fileName': filename,
            'isVideo': isVideo,
          },
        );
        return result != null && result.isNotEmpty;
      } else {
        // iOS fallback using path_provider
        Directory? downloadDir;
        try {
          downloadDir = await getDownloadsDirectory();
        } catch (_) {}
        downloadDir ??= await getApplicationDocumentsDirectory();

        final destDir = Directory('${downloadDir.path}/GPS Camera');
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        final destFile = File('${destDir.path}/$filename');
        await file.copy(destFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('Error saving image to downloads: $e');
      return false;
    }
  }
}
