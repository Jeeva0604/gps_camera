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

  /// Generates the standalone card watermark PNG bytes (e.g. for video overlay).
  static Future<Uint8List> renderCardWatermarkPng({
    required Uint8List mapBytes,
    required GpsPhotoData gpsData,
    double cardWidth = 720.0,
    double cardHeight = 280.0,
    bool? isDarkMode,
  }) async {
    final isDark = isDarkMode ?? ThemeService.instance.isDarkMode;
    return await CardWatermarkRenderer.renderCardPng(
      mapBytes: mapBytes,
      gpsData: gpsData,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      isDarkMode: isDark,
    );
  }

  /// Generates a transparent full-frame PNG (e.g. 1080x1920) with the GPS card
  /// positioned perfectly at the bottom, so it maps 1:1 onto video frames without distortion.
  static Future<Uint8List> renderFullFrameVideoOverlayPng({
    required Uint8List mapBytes,
    required GpsPhotoData gpsData,
    int frameWidth = 1080,
    int frameHeight = 1920,
    bool? isDarkMode,
  }) async {
    // Card width occupies ~92% of frame width
    final cardW = (frameWidth * 0.92).clamp(360, 1400).toDouble();
    final cardH = (cardW * 0.42).clamp(160, 560).toDouble();

    final cardPngBytes = await renderCardWatermarkPng(
      mapBytes: mapBytes,
      gpsData: gpsData,
      cardWidth: cardW,
      cardHeight: cardH,
      isDarkMode: isDarkMode,
    );

    final fullCanvas = img.Image(width: frameWidth, height: frameHeight, numChannels: 4);
    final cardImg = img.decodePng(cardPngBytes);
    if (cardImg != null) {
      final dstX = (frameWidth - cardImg.width) ~/ 2;
      // Position safely above navigation bar / bottom bezel (8% of frame height)
      final bottomMargin = (frameHeight * 0.08).toInt();
      final dstY = frameHeight - cardImg.height - bottomMargin;

      img.compositeImage(
        fullCanvas,
        cardImg,
        dstX: dstX,
        dstY: dstY > 0 ? dstY : 0,
      );
    }

    return Uint8List.fromList(img.encodePng(fullCanvas));
  }
}
