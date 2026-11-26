import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/gps_photo_data.dart';
import 'card_watermark_renderer.dart';
import 'theme_service.dart';

class WatermarkService {
  /// Stamps the captured photo with the floating GPS Map Camera satellite card.
  /// Renders razor-sharp vector typography, real national flag emoji, Plus Code,
  /// and Google Satellite map preview matching the reference design in Light or Dark theme.
  static Future<Uint8List> stampPhoto({
    required Uint8List photoBytes,
    required Uint8List mapBytes,
    required GpsPhotoData gpsData,
    bool? isDarkMode,
  }) async {
    // 1. Decode original captured photo
    img.Image? originalImage = img.decodeImage(photoBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode captured photo bytes.');
    }

    // 2. Bake EXIF orientation so portrait/landscape photos align correctly
    originalImage = img.bakeOrientation(originalImage);

    final imgW = originalImage.width;
    final imgH = originalImage.height;

    // 3. Calculate responsive card dimensions based on image size
    // Card occupies ~94% width, with ~2.5:1 to 2.8:1 aspect ratio
    final cardW = (imgW * 0.94).clamp(420, 1400).toDouble();
    final cardH = (cardW * 0.40).clamp(180, 560).toDouble();

    final isDark = isDarkMode ?? ThemeService.instance.isDarkMode;

    // 4. Render vector card PNG using Flutter engine (supports flag emojis & custom text)
    final cardPngBytes = await CardWatermarkRenderer.renderCardPng(
      mapBytes: mapBytes,
      gpsData: gpsData,
      cardWidth: cardW,
      cardHeight: cardH,
      isDarkMode: isDark,
    );

    // 5. Decode card PNG and composite onto the photo
    final cardImg = img.decodePng(cardPngBytes);
    if (cardImg != null) {
      final dstX = (imgW - cardImg.width) ~/ 2;
      final bottomMargin = (imgH * 0.025).clamp(16, 60).toInt();
      final dstY = imgH - cardImg.height - bottomMargin;

      img.compositeImage(
        originalImage,
        cardImg,
        dstX: dstX,
        dstY: dstY,
      );
    }

    // 6. Encode to high-quality JPEG
    final outputJpg = img.encodeJpg(originalImage, quality: 92);
    return Uint8List.fromList(outputJpg);
  }
}
