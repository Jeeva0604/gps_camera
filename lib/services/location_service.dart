import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gps_photo_data.dart';
import 'open_location_code.dart';

class LocationService {
  static final Map<String, Map<String, String?>> _memoryCache = {};
  static const String _prefCachedGpsDataKey = 'cached_gps_photo_data';
  static const String _prefCachedAddressKey = 'cached_address_map';

  /// Saves GpsPhotoData to SharedPreferences for instant recovery on next launch
  static Future<void> saveCachedGpsData(GpsPhotoData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCachedGpsDataKey, json.encode(data.toJson()));
    } catch (_) {}
  }

  /// Retrieves the last known GpsPhotoData from SharedPreferences (0ms on launch)
  static Future<GpsPhotoData?> getCachedGpsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefCachedGpsDataKey);
      if (raw != null && raw.isNotEmpty) {
        return GpsPhotoData.fromJson(json.decode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Stream for live GPS coordinates in the camera viewfinder HUD.
  /// Configured to stream continuously even when stationary.
  static Stream<Position> getPositionStream() {
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 2),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Fast one-shot position fetch that avoids long satellite lock stalls
  static Future<Position?> getFastCurrentPosition() async {
    try {
      // 1. Try high accuracy with brief 3s timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      try {
        // 2. Fast fallback to medium/balanced accuracy (cellular/WiFi)
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        // 3. Fallback to OS last known position
        return await Geolocator.getLastKnownPosition();
      }
    }
  }

  /// Reverse geocodes coordinates with in-memory grid cache and persistent fallback.
  static Future<Map<String, String?>> reverseGeocode(
      double lat, double lon) async {
    // 1. Check in-memory grid cache (~100m precision)
    final cacheKey =
        '${(lat * 1000).round() / 1000},${(lon * 1000).round() / 1000}';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Try OpenStreetMap Nominatim with quick 2.5s timeout
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'com.jera.gps_camera/1.0 (rajesht1989@gmail.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final result = {
            'locality': (addr['town'] ??
                    addr['city'] ??
                    addr['village'] ??
                    addr['suburb'] ??
                    addr['county'] ??
                    addr['municipality'])
                ?.toString(),
            'state': addr['state']?.toString(),
            'country': addr['country']?.toString(),
            'countryCode': addr['country_code']?.toString().toUpperCase(),
            'postalCode': addr['postcode']?.toString(),
            'street':
                (addr['road'] ?? addr['residential'] ?? addr['neighbourhood'])
                    ?.toString(),
            'displayName': data['display_name']?.toString(),
          };
          _memoryCache[cacheKey] = result;
          _persistAddress(result);
          return result;
        }
      }
    } catch (_) {}

    // 3. Fallback to Photon with quick 2.5s timeout
    try {
      final url =
          Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lon');
      final response =
          await http.get(url).timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final result = {
              'locality': (props['city'] ?? props['county'] ?? props['name'])
                  ?.toString(),
              'state': props['state']?.toString(),
              'country': props['country']?.toString(),
              'countryCode': props['countrycode']?.toString().toUpperCase(),
              'postalCode': props['postcode']?.toString(),
              'street': (props['street'] ?? props['name'])?.toString(),
              'displayName': props['name']?.toString(),
            };
            _memoryCache[cacheKey] = result;
            _persistAddress(result);
            return result;
          }
        }
      }
    } catch (_) {}

    // 4. Offline / slow connection: fallback to previously cached address
    final cached = await _getPersistedAddress();
    if (cached.isNotEmpty) {
      return cached;
    }

    return {};
  }

  static Future<void> _persistAddress(Map<String, String?> addr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCachedAddressKey, json.encode(addr));
    } catch (_) {}
  }

  static Future<Map<String, String?>> _getPersistedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefCachedAddressKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v?.toString()));
      }
    } catch (_) {}
    return {};
  }

  /// Fetches the most precise current position and reverse-geocodes it into GpsPhotoData.
  static Future<GpsPhotoData> getCaptureGpsData() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled on device. Please enable GPS.');
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      throw Exception(
          'Unable to obtain GPS fix. Please ensure location services are active.');
    }

    final geo = await reverseGeocode(position.latitude, position.longitude);
    final plusCode =
        OpenLocationCode.encode(position.latitude, position.longitude);

    return GpsPhotoData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
      timestamp: DateTime.now(),
      locality: geo['locality'],
      administrativeArea: geo['state'],
      country: geo['country'],
      countryCode: geo['countryCode'] ?? 'IN',
      postalCode: geo['postalCode'],
      street: geo['street'],
      plusCode: plusCode,
    );
  }

  /// Checks if location services are enabled on the device.
  static Future<bool> isLocationEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Requests user to enable location services or grant location permissions.
  static Future<bool> requestEnableLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
