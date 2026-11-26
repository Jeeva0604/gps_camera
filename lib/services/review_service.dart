import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Centralized service to request in-app ratings and reviews on Android & iOS
class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Optional App Store ID for iOS store listing fallback
  static const String appStoreId = '';

  /// Triggers the native in-app review dialog on Android & iOS after saving an image
  static Future<void> requestReviewAfterSave() async {
    try {
      // Allow user to see the "Photo saved!" notification toast first
      await Future.delayed(const Duration(milliseconds: 700));

      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
      } else {
        debugPrint('In-app review is not available on this device');
      }
    } catch (e) {
      debugPrint('Failed to request in-app review: $e');
    }
  }

  /// Opens the store listing page directly if needed
  static Future<void> openStoreListing() async {
    try {
      if (Platform.isIOS && appStoreId.isNotEmpty) {
        await _inAppReview.openStoreListing(appStoreId: appStoreId);
      } else {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('Failed to open store listing: $e');
    }
  }
}
