import 'package:intl/intl.dart';
import '../services/open_location_code.dart';

/// Data class holding GPS coordinates, reverse-geocoded address, and capture metadata.
class GpsPhotoData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double? heading;
  final DateTime timestamp;
  final String? street;
  final String? subLocality;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? countryCode;
  final String? postalCode;
  final String? plusCode;

  const GpsPhotoData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    this.heading,
    required this.timestamp,
    this.street,
    this.subLocality,
    this.locality,
    this.administrativeArea,
    this.country,
    this.countryCode,
    this.postalCode,
    this.plusCode,
  });

  /// Whether meaningful address components are present
  bool get hasAddress =>
      (locality != null && locality!.isNotEmpty) ||
      (subLocality != null && subLocality!.isNotEmpty) ||
      (administrativeArea != null && administrativeArea!.isNotEmpty) ||
      (street != null && street!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
        'street': street,
        'subLocality': subLocality,
        'locality': locality,
        'administrativeArea': administrativeArea,
        'country': country,
        'countryCode': countryCode,
        'postalCode': postalCode,
        'plusCode': plusCode,
      };

  factory GpsPhotoData.fromJson(Map<String, dynamic> json) => GpsPhotoData(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 5.0,
        heading: (json['heading'] as num?)?.toDouble(),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        street: json['street'] as String?,
        subLocality: json['subLocality'] as String?,
        locality: json['locality'] as String?,
        administrativeArea: json['administrativeArea'] as String?,
        country: json['country'] as String?,
        countryCode: json['countryCode'] as String?,
        postalCode: json['postalCode'] as String?,
        plusCode: json['plusCode'] as String?,
      );

  /// Computed Plus Code (e.g. "2j36+x8p")
  String get resolvedPlusCode {
    if (plusCode != null && plusCode!.isNotEmpty) return plusCode!;
    return OpenLocationCode.encode(latitude, longitude);
  }

  /// Line 1: City/Town, State, Country
  /// E.g. "Andippatti, Tamil Nadu, India"
  String get titleLocation {
    final parts = <String>[
      if (locality != null && locality!.isNotEmpty) locality!
      else if (subLocality != null && subLocality!.isNotEmpty) subLocality!,
      if (administrativeArea != null && administrativeArea!.isNotEmpty) administrativeArea!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return 'Location Details';
  }

  /// Line 2: Flag emoji (e.g. 🇮🇳)
  String get flagEmoji {
    final code = (countryCode ?? 'IN').toUpperCase();
    if (code.length == 2) {
      final first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
      final second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(first) + String.fromCharCode(second);
    }
    return '🇮🇳';
  }

  /// Line 3: Detailed Address with Plus Code
  /// E.g. "2j36+x8p, Andippatti, Tamil Nadu 625512, India"
  String get detailedAddressWithPlusCode {
    final code = resolvedPlusCode;
    final addressParts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      if (locality != null && locality!.isNotEmpty) locality!,
      if (administrativeArea != null && administrativeArea!.isNotEmpty)
        postalCode != null && postalCode!.isNotEmpty
            ? '${administrativeArea!} $postalCode'
            : administrativeArea!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    final addr = addressParts.join(', ');
    return '$code, $addr';
  }

  /// Line 4: Formatted coordinates e.g. "Lat 10.004815° Long 77.610326°"
  String get formattedLatLong {
    return 'Lat ${latitude.toStringAsFixed(6)}° Long ${longitude.toStringAsFixed(6)}°';
  }

  /// Line 5: Formatted timestamp e.g. "Sunday, 06/09/2026 03:11 PM GMT +05:30"
  String get formattedDateTimeWithGmt {
    final base = DateFormat('EEEE, MM/dd/yyyy hh:mm a').format(timestamp);
    final offset = timestamp.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$base GMT $sign$hours:$minutes';
  }

  /// Formatted decimal coordinates string e.g. "13.0827° N, 80.2707° E"
  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(5)}° $latDir, ${longitude.abs().toStringAsFixed(5)}° $lonDir';
  }

  /// Compact DMS (Degrees Minutes Seconds) string
  String get dmsCoordinates {
    return '${_toDms(latitude, isLat: true)}, ${_toDms(longitude, isLat: false)}';
  }

  /// Formatted date and time string e.g. "2026-10-08 14:15:20"
  String get formattedDateTime {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return dateFormat.format(timestamp);
  }

  /// Single line human-readable address summary
  String get fullAddress {
    final parts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      if (subLocality != null && subLocality!.isNotEmpty) subLocality!,
      if (locality != null && locality!.isNotEmpty) locality!,
      if (administrativeArea != null && administrativeArea!.isNotEmpty) administrativeArea!,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  static String _toDms(double deg, {required bool isLat}) {
    final dir = isLat ? (deg >= 0 ? 'N' : 'S') : (deg >= 0 ? 'E' : 'W');
    final abs = deg.abs();
    final d = abs.floor();
    final minFloat = (abs - d) * 60;
    final m = minFloat.floor();
    final s = ((minFloat - m) * 60).toStringAsFixed(1);
    return '$d°$m\'$s"$dir';
  }
}
