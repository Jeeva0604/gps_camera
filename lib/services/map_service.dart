import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class MapService {
  /// Optional Google Maps Static API Key. If empty, high-res tile services are used.
  static String googleMapsApiKey = '';

  /// Tile provider URL templates
  static const List<String> tileProviders = [
    // 1. Esri ArcGIS World Imagery: Global high-resolution Satellite & Aerial imagery
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    // 2. CartoDB Voyager: Highly detailed street map with crisp road geometry and English/local labels
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    // 3. OpenStreetMap Standard
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ];

  /// Returns a live map tile URL for the given coordinate and zoom level.
  /// Used by Flutter UI widgets (e.g. the viewfinder live minimap card).
  static String getTileUrl({
    required double latitude,
    required double longitude,
    int zoom = 16,
    int providerIndex = 0,
  }) {
    final n = pow(2.0, zoom);
    final x = ((longitude + 180.0) / 360.0 * n).floor();
    final latRad = latitude * pi / 180.0;
    final y =
        ((1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * n).floor();

    final template =
        tileProviders[providerIndex.clamp(0, tileProviders.length - 1)];
    return template
        .replaceAll('{z}', '$zoom')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  /// Fetches a high-resolution map snapshot centered precisely on (latitude, longitude).
  /// Stitches a 2x2 tile grid so the target coordinate is in the exact center,
  /// draws a modern GPS location pin, and returns the finished image bytes.
  static Future<Uint8List> getMapSnapshot({
    required double latitude,
    required double longitude,
    int width = 320,
    int height = 320,
    int zoom = 16,
  }) async {
    // 1. Check for custom Google Maps Static API Key first
    if (googleMapsApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/staticmap?'
          'center=$latitude,$longitude'
          '&zoom=$zoom'
          '&size=${width}x$height'
          '&scale=2'
          '&maptype=roadmap'
          '&markers=color:red%7C$latitude,$longitude'
          '&key=$googleMapsApiKey',
        );
        final response =
            await http.get(url).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }

    // 2. Fetch and stitch high-resolution tiles from reliable map providers
    for (int providerIdx = 0;
        providerIdx < tileProviders.length;
        providerIdx++) {
      try {
        final stitchedBytes = await _stitchCenteredMap(
          latitude: latitude,
          longitude: longitude,
          width: width,
          height: height,
          zoom: zoom,
          providerIndex: providerIdx,
        );
        if (stitchedBytes != null) {
          return stitchedBytes;
        }
      } catch (_) {
        // Fall through to next tile provider on failure
      }
    }

    // 3. Fallback: Generate a clean styled vector-like map card if completely offline
    return _generateOfflineMapPlaceholder(latitude, longitude, width, height);
  }

  /// Downloads the 2x2 tile quadrant surrounding (latitude, longitude),
  /// composites them into a seamless canvas, crops centered on the coordinates,
  /// and draws a clean GPS pin marker.
  static Future<Uint8List?> _stitchCenteredMap({
    required double latitude,
    required double longitude,
    required int width,
    required int height,
    required int zoom,
    required int providerIndex,
  }) async {
    final n = pow(2.0, zoom);
    final xExact = (longitude + 180.0) / 360.0 * n;
    final latRad = latitude * pi / 180.0;
    final yExact =
        (1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * n;

    final xCenter = xExact.floor();
    final yCenter = yExact.floor();

    // Fractional pixel offset within central tile
    final fracX = (xExact - xCenter) * 256.0;
    final fracY = (yExact - yCenter) * 256.0;

    // Pick 2x2 grid so coordinates are well inside the 512x512 canvas
    final int x0 = fracX < 128 ? xCenter - 1 : xCenter;
    final int y0 = fracY < 128 ? yCenter - 1 : yCenter;
    final int x1 = x0 + 1;
    final int y1 = y0 + 1;

    final template = tileProviders[providerIndex];

    // Download 4 tiles concurrently in parallel
    final tileFutures = [
      _fetchTileImage(template, zoom, x0, y0),
      _fetchTileImage(template, zoom, x1, y0),
      _fetchTileImage(template, zoom, x0, y1),
      _fetchTileImage(template, zoom, x1, y1),
    ];

    final tiles = await Future.wait(tileFutures);
    final t00 = tiles[0];
    final t10 = tiles[1];
    final t01 = tiles[2];
    final t11 = tiles[3];

    // If any tile failed, try single central tile fallback
    if (t00 == null || t10 == null || t01 == null || t11 == null) {
      final single = await _fetchTileImage(template, zoom, xCenter, yCenter);
      if (single != null) {
        return _decorateSingleTile(single, width, height);
      }
      return null;
    }

    // Stitch 4 tiles onto a 512x512 canvas
    final canvas = img.Image(width: 512, height: 512);
    img.compositeImage(canvas, t00, dstX: 0, dstY: 0);
    img.compositeImage(canvas, t10, dstX: 256, dstY: 0);
    img.compositeImage(canvas, t01, dstX: 0, dstY: 256);
    img.compositeImage(canvas, t11, dstX: 256, dstY: 256);

    // Coordinate of user in 512x512 space
    final userPixelX = (xExact - x0) * 256.0;
    final userPixelY = (yExact - y0) * 256.0;

    // Crop window centered on (userPixelX, userPixelY)
    final cropX = (userPixelX - width / 2.0).round().clamp(0, 512 - width);
    final cropY = (userPixelY - height / 2.0).round().clamp(0, 512 - height);

    img.Image cropped = img.copyCrop(
      canvas,
      x: cropX,
      y: cropY,
      width: width,
      height: height,
    );

    // Return the clean cropped satellite map tile without hardcoded baked-in circles.
    // The exact prominent pin and Google logo are overlaid consistently by the renderer.
    return Uint8List.fromList(img.encodePng(cropped));
  }

  static Future<img.Image?> _fetchTileImage(
      String template, int z, int x, int y) async {
    try {
      final url = template
          .replaceAll('{z}', '$z')
          .replaceAll('{x}', '$x')
          .replaceAll('{y}', '$y');

      final res = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent': 'com.jera.gps_camera/1.0 (rajesht1989@gmail.com)',
          'Accept': 'image/webp,image/png,image/jpeg,*/*',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return img.decodeImage(res.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  static Uint8List _decorateSingleTile(img.Image tile, int w, int h) {
    final resized = img.copyResize(tile, width: w, height: h);
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Creates a styled offline map card showing grid lines, compass markings, and GPS text.
  static Uint8List _generateOfflineMapPlaceholder(
      double lat, double lon, int w, int h) {
    final image = img.Image(width: w, height: h);
    // Background soft map-like canvas color
    img.fill(image, color: img.ColorRgb8(238, 242, 246));

    // Draw subtle map grid lines
    final gridColor = img.ColorRgb8(210, 220, 230);
    for (int x = 0; x < w; x += 32) {
      img.drawLine(image, x1: x, y1: 0, x2: x, y2: h, color: gridColor);
    }
    for (int y = 0; y < h; y += 32) {
      img.drawLine(image, x1: 0, y1: y, x2: w, y2: y, color: gridColor);
    }

    // Concentric GPS target circles
    final cx = w ~/ 2;
    final cy = h ~/ 2;
    img.drawCircle(image,
        x: cx, y: cy, radius: 45, color: img.ColorRgb8(180, 200, 220));
    img.drawCircle(image,
        x: cx, y: cy, radius: 25, color: img.ColorRgb8(56, 189, 248));

    // Center pin
    img.fillCircle(image,
        x: cx + 1, y: cy + 2, radius: 8, color: img.ColorRgb8(100, 100, 100));
    img.fillCircle(image,
        x: cx, y: cy, radius: 8, color: img.ColorRgb8(239, 68, 68));
    img.fillCircle(image,
        x: cx, y: cy, radius: 3, color: img.ColorRgb8(255, 255, 255));

    // Heading labels
    img.drawString(image, 'N',
        font: img.arial14,
        x: cx - 4,
        y: 8,
        color: img.ColorRgb8(100, 116, 139));
    img.drawString(image, 'GPS LOCKED',
        font: img.arial14,
        x: 10,
        y: h - 22,
        color: img.ColorRgb8(15, 118, 110));

    return Uint8List.fromList(img.encodePng(image));
  }
}
