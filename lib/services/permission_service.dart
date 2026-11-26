import 'package:permission_handler/permission_handler.dart';

class PermissionStatusResult {
  final bool hasCamera;
  final bool hasLocation;
  final bool isGranted;

  PermissionStatusResult({
    required this.hasCamera,
    required this.hasLocation,
  }) : isGranted = hasCamera && hasLocation;
}

class PermissionService {
  /// Checks if both Camera and Location permissions are currently granted.
  static Future<PermissionStatusResult> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    return PermissionStatusResult(
      hasCamera: cameraStatus.isGranted,
      hasLocation: locationStatus.isGranted,
    );
  }

  /// Requests both Camera and Location permissions.
  static Future<PermissionStatusResult> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();

    final hasCamera = statuses[Permission.camera]?.isGranted ?? false;
    final hasLocation = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    return PermissionStatusResult(
      hasCamera: hasCamera,
      hasLocation: hasLocation,
    );
  }

  /// Opens app settings if user permanently denied permissions.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

