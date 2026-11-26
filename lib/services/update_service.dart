import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update_flutter/in_app_update_flutter.dart';

import '../utils/toast_helper.dart';

/// Centralized service to check and prompt for in-app updates across Android and iOS
class UpdateService {
  static final InAppUpdateFlutter _updater = InAppUpdateFlutter();
  static bool _isChecking = false;

  /// Optional numeric App Store ID (found in App Store Connect URL)
  static const String appStoreId = '';

  /// Bundle ID for iOS App Store lookup
  static const String iOSBundleId = 'com.jera.gps_camera';

  /// Current app version
  static const String currentAppVersion = '1.0.1';

  /// Checks for available in-app updates on Android (Play Core) and iOS (StoreKit).
  /// [showFeedbackOnLatest]: when true (e.g. from Settings), informs the user if they're on the latest version.
  static Future<void> checkForUpdate(
      {bool showFeedbackOnLatest = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      if (Platform.isAndroid) {
        await _checkAndroidUpdate(showFeedbackOnLatest: showFeedbackOnLatest);
      } else if (Platform.isIOS) {
        await _checkIosUpdate(showFeedbackOnLatest: showFeedbackOnLatest);
      }
    } catch (e) {
      debugPrint('UpdateService check error: $e');
      if (showFeedbackOnLatest) {
        ToastHelper.show('App is up to date (v$currentAppVersion)');
      }
    } finally {
      _isChecking = false;
    }
  }

  static Future<void> _checkAndroidUpdate(
      {bool showFeedbackOnLatest = false}) async {
    try {
      final updateInfo = await _updater.checkUpdateAndroid();

      if (updateInfo.updateAvailability ==
              UpdateAvailabilityAndroid.updateAvailable ||
          updateInfo.updateAvailability ==
              UpdateAvailabilityAndroid.developerTriggeredUpdateInProgress) {
        // If an update was previously downloaded, complete it immediately
        if (updateInfo.installStatus == InstallStatusAndroid.downloaded) {
          await _updater.completeUpdateAndroid();
          return;
        }

        // Prefer flexible update in the background so user flow is uninterrupted
        if (updateInfo.isFlexibleUpdateAllowed) {
          _updater.installStateStreamAndroid.listen((state) {
            if (state.status == InstallStatusAndroid.downloaded) {
              _updater.completeUpdateAndroid();
            }
          });
          await _updater.startFlexibleUpdateAndroid();
        } else if (updateInfo.isImmediateUpdateAllowed) {
          // Fallback to immediate full-screen update
          await _updater.startImmediateUpdateAndroid();
        }
      } else {
        if (showFeedbackOnLatest) {
          ToastHelper.show('App is up to date (v$currentAppVersion)');
        }
      }
    } catch (e) {
      // Sideloaded APKs or debug builds throw when Play Core is not connected to Play Store
      debugPrint('Android In-App Update: $e');
      if (showFeedbackOnLatest) {
        ToastHelper.show('App is up to date (v$currentAppVersion)');
      }
    }
  }

  static Future<void> _checkIosUpdate(
      {bool showFeedbackOnLatest = false}) async {
    try {
      String targetAppStoreId = appStoreId;
      bool hasUpdate = false;

      // If no explicit appStoreId is specified, query iTunes lookup API
      if (targetAppStoreId.isEmpty) {
        final url = Uri.parse(
          'https://itunes.apple.com/lookup?bundleId=$iOSBundleId',
        );
        final response =
            await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['resultCount'] != null && data['resultCount'] > 0) {
            final result = data['results'][0];
            final storeVersion = result['version']?.toString() ?? '';
            final trackId = result['trackId']?.toString() ?? '';

            if (trackId.isNotEmpty &&
                _isNewerVersion(storeVersion, currentAppVersion)) {
              targetAppStoreId = trackId;
              hasUpdate = true;
            }
          }
        }
      }

      if (targetAppStoreId.isNotEmpty && hasUpdate) {
        await _updater.showUpdateForIos(appStoreId: targetAppStoreId);
      } else if (showFeedbackOnLatest) {
        ToastHelper.show('App is up to date (v$currentAppVersion)');
      }
    } catch (e) {
      debugPrint('iOS In-App Update: $e');
      if (showFeedbackOnLatest) {
        ToastHelper.show('App is up to date (v$currentAppVersion)');
      }
    }
  }

  static bool _isNewerVersion(String storeVersion, String currentVersion) {
    try {
      final storeParts =
          storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = currentVersion
          .split('+')[0]
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final maxLen = storeParts.length > currentParts.length
          ? storeParts.length
          : currentParts.length;
      for (int i = 0; i < maxLen; i++) {
        final s = i < storeParts.length ? storeParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (s > c) return true;
        if (s < c) return false;
      }
    } catch (_) {}
    return false;
  }
}
