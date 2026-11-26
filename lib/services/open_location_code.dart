class OpenLocationCode {
  static const String _alphabet = '23456789CFGHJMPQRVWX';
  static const double _latitudeMax = 90.0;
  static const double _longitudeMax = 180.0;

  /// Encodes latitude and longitude into an Open Location Code (Plus Code).
  /// Returns a clean lowercase short local code e.g. "2j36+x8p".
  static String encode(double latitude, double longitude) {
    double lat = latitude.clamp(-_latitudeMax, _latitudeMax);
    double lon = longitude;
    while (lon < -_longitudeMax) {
      lon += 360.0;
    }
    while (lon >= _longitudeMax) {
      lon -= 360.0;
    }

    lat += 90.0;
    lon += 180.0;

    final buffer = StringBuffer();
    double latVal = lat;
    double lonVal = lon;
    double latGridSize = 20.0;
    double lonGridSize = 20.0;

    for (int i = 0; i < 5; i++) {
      if (i == 4) buffer.write('+');
      final latDigit = (latVal / latGridSize).floor().clamp(0, 19);
      final lonDigit = (lonVal / lonGridSize).floor().clamp(0, 19);
      buffer.write(_alphabet[latDigit]);
      buffer.write(_alphabet[lonDigit]);
      latVal -= latDigit * latGridSize;
      lonVal -= lonDigit * lonGridSize;
      latGridSize /= 20.0;
      lonGridSize /= 20.0;
    }

    final full = buffer.toString().toLowerCase();
    // Return local 4+2 code (skip first 4 regional digits), e.g. "2j36+w4" or full
    return full.length >= 8 ? full.substring(4) : full;
  }
}
