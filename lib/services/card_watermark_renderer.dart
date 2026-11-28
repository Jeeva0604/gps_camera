import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/gps_photo_data.dart';
import 'template_service.dart';

class CardWatermarkRenderer {
  /// Renders the floating GPS Map Camera satellite card with:
  /// - Above Card: Clean pill badge with real app logo and "GPS Map Camera" title
  /// - Main Card:
  ///   - Left: Satellite map thumbnail rendered with selected CardTemplate
  ///     (Classic, Circular, Polaroid, Organic Leaf, Golden Halo, Hexagon)
  ///   - Right: Location title, GPS fix distance badge, flag emoji, detailed Plus Code address,
  ///     Lat/Long, and GMT timestamp.
  /// Exactly matches the typography (GoogleSans), font sizes, weights, and layout of GpsMinimapCard.
  static Future<Uint8List> renderCardPng({
    required Uint8List mapBytes,
    required GpsPhotoData gpsData,
    required double cardWidth,
    double? cardHeight,
    bool isDarkMode = true,
    CardTemplate? template,
  }) async {
    final activeTemplate = template ?? TemplateService.instance.currentTemplate;
    // Reference base width of GpsMinimapCard on phone screen is 360.0
    final scale = (cardWidth / 360.0).clamp(1.0, 4.5);
    final cardPadding = 10.0 * scale;
    final rrectRadius = Radius.circular(16.0 * scale);
    final mapSize = 96.0 * scale;

    // Dimensions for top badge positioned ABOVE the card
    final badgeGap = 6.0 * scale;

    // Load actual App Logo from assets
    ui.Image? appLogoImage;
    try {
      final logoData = await rootBundle.load('assets/icon/app_icon.png');
      final logoCodec =
          await ui.instantiateImageCodec(logoData.buffer.asUint8List());
      final logoFrame = await logoCodec.getNextFrame();
      appLogoImage = logoFrame.image;
    } catch (_) {}

    // Prepare Top Badge TextPainter using GoogleSans (matching GpsMinimapCard: 11.5, bold)
    final badgeTextSpan = TextSpan(
      text: 'GPS Camera',
      style: TextStyle(
        fontFamily: 'GoogleSans',
        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        fontSize: 11.5 * scale,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
    final badgePainter = TextPainter(
      text: badgeTextSpan,
      textDirection: TextDirection.ltr,
    );
    badgePainter.layout();

    final iconBoxSize = 18.0 * scale;
    final badgePadV = 5.0 * scale;
    final badgeHeight = max(iconBoxSize, badgePainter.height) + (badgePadV * 2);
    final cardTop = badgeHeight + badgeGap;

    final borderMargin = 6.0 * scale; // Buffer margin so borders & shadows are never cut off
    final actualCardWidth = cardWidth - (borderMargin * 2);
    final cardLeft = borderMargin;

    // Right Content Column width and positioning
    final textStartX = cardLeft + cardPadding + mapSize + (10.0 * scale);
    final textAvailableWidth = actualCardWidth - (cardPadding * 2) - mapSize - (10.0 * scale);

    // Theme-based colors
    final titleTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final addressTextColor =
        isDarkMode ? const Color(0xFFEEEEEE) : const Color(0xFF334155);
    final coordsTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final timeTextColor =
        isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF64748B);

    // Line 1: Locality, State, Country (matching GpsMinimapCard: 14.5, bold, GoogleSans, height 1.2)
    final distanceBadgeWidth = 62.0 * scale;
    final titleMaxW = textAvailableWidth - distanceBadgeWidth;

    double titleFontSize = 14.5 * scale;
    TextPainter titlePainter;
    while (true) {
      final titleSpan = TextSpan(
        text: gpsData.titleLocation,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          color: titleTextColor,
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );
      titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      titlePainter.layout(maxWidth: titleMaxW);
      if (!titlePainter.didExceedMaxLines || titleFontSize <= 10.5 * scale) {
        break;
      }
      titleFontSize -= 0.5 * scale;
    }
    if (titlePainter.didExceedMaxLines) {
      titlePainter = TextPainter(
        text: TextSpan(
          text: gpsData.titleLocation,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            color: titleTextColor,
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      );
      titlePainter.layout(maxWidth: textAvailableWidth);
    }

    // Line 2: Country Flag Emoji (matching GpsMinimapCard: 18.5)
    final flagSpan = TextSpan(
      text: gpsData.flagEmoji,
      style: TextStyle(
        fontSize: 18.5 * scale,
      ),
    );
    final flagPainter = TextPainter(
      text: flagSpan,
      textDirection: TextDirection.ltr,
    );
    flagPainter.layout();

    // Line 3: Detailed Address with Plus Code (matching GpsMinimapCard: 11.0, GoogleSans, height 1.25)
    double addressFontSize = 11.0 * scale;
    TextPainter addressPainter;
    while (true) {
      final addressSpan = TextSpan(
        text: gpsData.detailedAddressWithPlusCode,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          color: addressTextColor,
          fontSize: addressFontSize,
          fontWeight: FontWeight.w400,
          height: 1.25,
        ),
      );
      addressPainter = TextPainter(
        text: addressSpan,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      );
      addressPainter.layout(maxWidth: textAvailableWidth);
      if (!addressPainter.didExceedMaxLines || addressFontSize <= 8.5 * scale) {
        break;
      }
      addressFontSize -= 0.5 * scale;
    }

    // Line 4: Formatted Coordinates (matching GpsMinimapCard: 11.5, w500, GoogleSans)
    final coordsSpan = TextSpan(
      text: gpsData.formattedLatLong,
      style: TextStyle(
        fontFamily: 'GoogleSans',
        color: coordsTextColor,
        fontSize: 11.5 * scale,
        fontWeight: FontWeight.w500,
      ),
    );
    final coordsPainter = TextPainter(
      text: coordsSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    coordsPainter.layout(maxWidth: textAvailableWidth);

    // Line 5: Formatted Timestamp with Day and GMT (matching GpsMinimapCard: 10.5, GoogleSans)
    final timeSpan = TextSpan(
      text: gpsData.formattedDateTimeWithGmt,
      style: TextStyle(
        fontFamily: 'GoogleSans',
        color: timeTextColor,
        fontSize: 10.5 * scale,
        fontWeight: FontWeight.w400,
      ),
    );
    final timePainter = TextPainter(
      text: timeSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    timePainter.layout(maxWidth: textAvailableWidth);

    // Calculate total content height matching GpsMinimapCard's flexible layout
    final textColumnHeight = titlePainter.height +
        (1.0 * scale) +
        flagPainter.height +
        (2.0 * scale) +
        addressPainter.height +
        (3.0 * scale) +
        coordsPainter.height +
        (2.0 * scale) +
        timePainter.height;

    final contentHeight = max(mapSize, textColumnHeight);
    final actualCardHeight = contentHeight + (cardPadding * 2);
    final totalCanvasHeight = actualCardHeight + badgeHeight + badgeGap + (borderMargin * 2);

    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, cardWidth, totalCanvasHeight));

    // Decode satellite map image to ui.Image
    final mapCodec = await ui.instantiateImageCodec(mapBytes);
    final mapFrame = await mapCodec.getNextFrame();
    final mapImage = mapFrame.image;

    // 1. Draw Top Badge with App Logo & App Name ABOVE the Location Card (aligned right)
    _drawTopBadge(
      canvas,
      cardWidth,
      borderMargin,
      scale,
      appLogoImage,
      badgePainter,
      badgeHeight,
      isDarkMode,
    );

    // 2. Draw Main Location Card Background & Border (with ambient drop shadow)
    final cardRect = Rect.fromLTWH(cardLeft, cardTop, actualCardWidth, actualCardHeight);
    final cardRRect = RRect.fromRectAndRadius(cardRect, rrectRadius);

    // Drop shadow under card for crisp distinction from photo
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDarkMode ? 0.6 : 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale);
    canvas.drawRRect(cardRRect.shift(Offset(0, 3.0 * scale)), shadowPaint);

    final cardBgPaint = Paint()
      ..color = isDarkMode
          ? const Color(0xF21E232B) // High opacity deep charcoal
          : const Color(0xFAFFFFFF) // Crisp frosted white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRRect, cardBgPaint);

    // Template specific card border (high contrast & clearly visible on all 4 sides)
    final Color borderStrokeColor;
    switch (activeTemplate) {
      case CardTemplate.classic:
        borderStrokeColor = isDarkMode
            ? const Color(0x70FFFFFF) // Distinct white border
            : const Color(0x40000000); // Distinct dark border
        break;
      case CardTemplate.circular:
        borderStrokeColor = const Color(0xFF3B82F6);
        break;
      case CardTemplate.polaroid:
        borderStrokeColor = const Color(0xFFFB7185);
        break;
      case CardTemplate.organic:
        borderStrokeColor = const Color(0xFF10B981);
        break;
      case CardTemplate.golden:
        borderStrokeColor = const Color(0xFFFBBF24);
        break;
      case CardTemplate.hexagon:
        borderStrokeColor = const Color(0xFFA855F7);
        break;
    }

    final borderPaint = Paint()
      ..color = borderStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale;
    canvas.drawRRect(cardRRect, borderPaint);

    // 3. Draw Satellite Map Box using the active CardTemplate
    final mapLeft = cardLeft + cardPadding;
    final mapTop = cardTop + cardPadding;
    _drawTemplateMap(
      canvas,
      activeTemplate,
      mapImage,
      mapLeft,
      mapTop,
      mapSize,
      scale,
      isDarkMode,
    );

    // 4. Draw Right Content Column with exact GpsMinimapCard layout
    double currentY = cardTop + cardPadding;

    titlePainter.paint(canvas, Offset(textStartX, currentY));

    // Draw GPS Tag Badge beside title
    _drawGpsTagBadge(
      canvas,
      activeTemplate,
      cardLeft + actualCardWidth - cardPadding - (56.0 * scale),
      currentY + (1.0 * scale),
      scale,
      isDarkMode,
    );

    currentY += titlePainter.height + (1.0 * scale);

    flagPainter.paint(canvas, Offset(textStartX, currentY));
    currentY += flagPainter.height + (2.0 * scale);

    addressPainter.paint(canvas, Offset(textStartX, currentY));
    currentY += addressPainter.height + (3.0 * scale);

    coordsPainter.paint(canvas, Offset(textStartX, currentY));
    currentY += coordsPainter.height + (2.0 * scale);

    timePainter.paint(canvas, Offset(textStartX, currentY));

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(cardWidth.toInt(), totalCanvasHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Draws the top-right badge with real App Logo positioned ABOVE the location card
  /// Matches GpsMinimapCard: padding (10, 5), icon size 18, font 11.5 bold GoogleSans
  static void _drawTopBadge(
    Canvas canvas,
    double cardW,
    double borderMargin,
    double scale,
    ui.Image? appLogoImage,
    TextPainter badgePainter,
    double badgeHeight,
    bool isDarkMode,
  ) {
    final iconBoxSize = 18.0 * scale;
    final padH = 10.0 * scale;
    final gap = 6.0 * scale;
    final badgeWidth = padH + iconBoxSize + gap + badgePainter.width + padH;
    final badgeX = cardW - borderMargin - badgeWidth - (10.0 * scale);
    final badgeY = borderMargin;

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
      Radius.circular(6.0 * scale),
    );

    // Badge pill background
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color =
            isDarkMode ? const Color(0xE81E242C) : const Color(0xF2FFFFFF),
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = isDarkMode
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // App Logo icon container on left of badge
    final iconBoxLeft = badgeX + padH;
    final iconBoxTop = badgeY + ((badgeHeight - iconBoxSize) / 2);
    final iconRect =
        Rect.fromLTWH(iconBoxLeft, iconBoxTop, iconBoxSize, iconBoxSize);
    final iconRRect =
        RRect.fromRectAndRadius(iconRect, Radius.circular(4.0 * scale));

    if (appLogoImage != null) {
      canvas.save();
      canvas.clipRRect(iconRRect);
      canvas.drawImageRect(
        appLogoImage,
        Rect.fromLTWH(0, 0, appLogoImage.width.toDouble(),
            appLogoImage.height.toDouble()),
        iconRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } else {
      // Fallback vector icon
      canvas.drawRRect(iconRRect, Paint()..color = const Color(0xFF38BDF8));
      final iconCx = iconBoxLeft + (iconBoxSize / 2);
      final iconCy = iconBoxTop + (iconBoxSize / 2);
      canvas.drawCircle(Offset(iconCx, iconCy), 4.0 * scale,
          Paint()..color = const Color(0xFF0F172A));
      canvas.drawCircle(Offset(iconCx, iconCy), 2.0 * scale,
          Paint()..color = const Color(0xFF38BDF8));
    }

    badgePainter.paint(
      canvas,
      Offset(iconBoxLeft + iconBoxSize + gap,
          badgeY + ((badgeHeight - badgePainter.height) / 2)),
    );
  }

  static void _drawRedMapPin(
      Canvas canvas, double cx, double cy, double scale) {
    // In GpsMinimapCard: ProminentMapPin(size: 28) inside a 96x96 box -> 28/96 ratio
    final w = 28.0 * scale;
    final h = 28.0 * scale;

    // Ground contact shadow under tip
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + (h * 0.46)),
        width: w * 0.38,
        height: h * 0.14,
      ),
      shadowPaint,
    );

    final r = w * 0.35;
    final headCenterY = cy - (h * 0.14);
    final tipY = cy + (h * 0.44);

    final d = tipY - headCenterY;
    final alpha = asin((r / d).clamp(0.0, 1.0));

    final leftTangent = Offset(
      cx - (r * cos(alpha)),
      headCenterY + (r * sin(alpha)),
    );
    final rightTangent = Offset(
      cx + (r * cos(alpha)),
      headCenterY + (r * sin(alpha)),
    );

    final pinPath = Path();
    pinPath.moveTo(cx, tipY);
    pinPath.lineTo(leftTangent.dx, leftTangent.dy);
    pinPath.arcToPoint(
      rightTangent,
      radius: Radius.circular(r),
      largeArc: true,
      clockwise: true,
    );
    pinPath.lineTo(cx, tipY);
    pinPath.close();

    // High-contrast white border
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pinPath, outlinePaint);

    // Authentic Google Red fill
    final fillPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // Center white hole
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, headCenterY), r * 0.44, holePaint);
  }

  static void _drawGoogleLogo(Canvas canvas, double x, double y, double scale) {
    final textSpan = TextSpan(
      text: 'Google',
      style: TextStyle(
        fontFamily: 'GoogleSans',
        color: Colors.white,
        fontSize: 10.0 * scale,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 3.0 * scale,
            offset: Offset(1.0 * scale, 1.0 * scale),
          ),
        ],
      ),
    );
    final painter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, Offset(x, y));
  }

  /// Draws the satellite map using the specified template design
  static void _drawTemplateMap(
    Canvas canvas,
    CardTemplate template,
    ui.Image mapImage,
    double mapLeft,
    double mapTop,
    double mapSize,
    double scale,
    bool isDarkMode,
  ) {
    final mapRect = Rect.fromLTWH(mapLeft, mapTop, mapSize, mapSize);
    final cx = mapLeft + (mapSize / 2);
    final cy = mapTop + (mapSize / 2);

    canvas.save();

    switch (template) {
      case CardTemplate.classic:
        final mapRRect =
            RRect.fromRectAndRadius(mapRect, Radius.circular(10.0 * scale));
        canvas.clipRRect(mapRRect);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        _drawGoogleLogo(canvas, mapLeft + (5.0 * scale),
            mapTop + mapSize - (16.0 * scale), scale);
        canvas.restore();

        final mapBorderPaint = Paint()
          ..color = isDarkMode
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * scale;
        canvas.drawRRect(mapRRect, mapBorderPaint);
        break;

      case CardTemplate.circular:
        final circlePath = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: mapSize / 2));
        canvas.clipPath(circlePath);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        _drawGoogleLogo(canvas, mapLeft + (12.0 * scale),
            mapTop + mapSize - (18.0 * scale), scale);
        canvas.restore();

        final ringPaint = Paint()
          ..color = const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * scale;
        canvas.drawCircle(Offset(cx, cy), mapSize / 2, ringPaint);
        break;

      case CardTemplate.polaroid:
        canvas.translate(cx, cy);
        canvas.rotate(-0.05);
        canvas.translate(-cx, -cy);

        final frameRect =
            Rect.fromLTWH(mapLeft - (2 * scale), mapTop - (2 * scale),
                mapSize + (4 * scale), mapSize + (4 * scale));
        final frameRRect =
            RRect.fromRectAndRadius(frameRect, Radius.circular(6.0 * scale));
        canvas.drawRRect(frameRRect, Paint()..color = Colors.white);

        final innerRRect =
            RRect.fromRectAndRadius(mapRect, Radius.circular(4.0 * scale));
        canvas.clipRRect(innerRRect);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        canvas.restore();
        break;

      case CardTemplate.organic:
        final rrect =
            RRect.fromRectAndRadius(mapRect, Radius.circular(20.0 * scale));
        canvas.clipRRect(rrect);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        _drawGoogleLogo(canvas, mapLeft + (6.0 * scale),
            mapTop + mapSize - (16.0 * scale), scale);
        canvas.restore();

        final borderPaint = Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * scale;
        canvas.drawRRect(rrect, borderPaint);

        // Draw little green leaf badge on bottom-left
        final leafCx = mapLeft + (4.0 * scale);
        final leafCy = mapTop + mapSize - (4.0 * scale);
        canvas.drawCircle(
            Offset(leafCx, leafCy), 8.0 * scale, Paint()..color = const Color(0xFF10B981));
        canvas.drawCircle(
            Offset(leafCx, leafCy), 5.0 * scale, Paint()..color = Colors.white);
        break;

      case CardTemplate.golden:
        final circlePath = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: mapSize / 2));
        canvas.clipPath(circlePath);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        _drawGoogleLogo(canvas, mapLeft + (12.0 * scale),
            mapTop + mapSize - (18.0 * scale), scale);
        canvas.restore();

        final ringPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * scale;
        canvas.drawCircle(Offset(cx, cy), mapSize / 2, ringPaint);
        break;

      case CardTemplate.hexagon:
        final hexPath = _createHexagonPath(mapRect);
        canvas.clipPath(hexPath);
        _drawMapImage(canvas, mapImage, mapRect);
        _drawRedMapPin(canvas, cx, cy, scale);
        canvas.restore();

        final hexBorder = Paint()
          ..color = const Color(0xFF8B5CF6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * scale;
        canvas.drawPath(hexPath, hexBorder);
        break;
    }
  }

  static void _drawMapImage(Canvas canvas, ui.Image mapImage, Rect mapRect) {
    canvas.drawImageRect(
      mapImage,
      Rect.fromLTWH(
          0, 0, mapImage.width.toDouble(), mapImage.height.toDouble()),
      mapRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  static Path _createHexagonPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;

    path.moveTo(l + (w * 0.5), t);
    path.lineTo(l + w, t + (h * 0.25));
    path.lineTo(l + w, t + (h * 0.75));
    path.lineTo(l + (w * 0.5), t + h);
    path.lineTo(l, t + (h * 0.75));
    path.lineTo(l, t + (h * 0.25));
    path.close();
    return path;
  }

  static void _drawGpsTagBadge(
    Canvas canvas,
    CardTemplate template,
    double x,
    double y,
    double scale,
    bool isDarkMode,
  ) {
    final badgeW = 54.0 * scale;
    final badgeH = 16.0 * scale;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, badgeW, badgeH), Radius.circular(8.0 * scale));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = template.accentColor.withValues(alpha: isDarkMode ? 0.25 : 0.15),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = template.accentColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale,
    );

    final textSpan = TextSpan(
      text: 'GPS FIX',
      style: TextStyle(
        fontFamily: 'GoogleSans',
        color: template.accentColor,
        fontSize: 8.5 * scale,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
    final painter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas,
        Offset(x + ((badgeW - painter.width) / 2), y + ((badgeH - painter.height) / 2)));
  }
}
