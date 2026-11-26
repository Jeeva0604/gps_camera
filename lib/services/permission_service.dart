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
    final locationWhenInUse = await Permission.locationWhenInUse.status;
    final locationAlways = await Permission.locationAlways.status;
    final locationCoarse = await Permission.location.status;

    final hasLocation = locationWhenInUse.isGranted ||
        locationAlways.isGranted ||
        locationCoarse.isGranted;

    return PermissionStatusResult(
      hasCamera: cameraStatus.isGranted,
      hasLocation: hasLocation,
    );
  }

  /// Requests both Camera and Location permissions.
  static Future<PermissionStatusResult> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    final hasCamera = statuses[Permission.camera]?.isGranted ?? false;
    final hasLocation = (statuses[Permission.locationWhenInUse]?.isGranted ?? false) ||
        (statuses[Permission.location]?.isGranted ?? false);

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

