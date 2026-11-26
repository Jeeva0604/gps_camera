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
  static Future<bool> saveToGallery(File file) async {
    return saveToDownloads(file);
  }

  /// Saves the stamped image file directly to the device's Downloads directory.
  /// On Android, uses native Kotlin MediaStore.Downloads API (requires zero dangerous permissions).
  /// On iOS, saves to the app's accessible Documents/Downloads directory.
  static Future<bool> saveToDownloads(File file) async {
    try {
      if (!await file.exists()) return false;

      final filename = 'GPS_PHOTO_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Native Android Kotlin call to MediaStore.Downloads
        final String? result = await _channel.invokeMethod<String>(
          'saveToDownloads',
          {
            'filePath': file.path,
            'fileName': filename,
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
