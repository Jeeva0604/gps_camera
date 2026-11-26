import 'package:permission_handler/permission_handler.dart';

class PermissionStatusResult {
  final bool hasCamera;
  final bool hasLocation;
  final bool hasMicrophone;
  final bool isGranted;

  PermissionStatusResult({
    required this.hasCamera,
    required this.hasLocation,
    required this.hasMicrophone,
  }) : isGranted = hasCamera && hasLocation && hasMicrophone;
}

class PermissionService {
  /// Checks if Camera, Location, and Microphone permissions are all currently granted.
  static Future<PermissionStatusResult> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    final locationWhenInUse = await Permission.locationWhenInUse.status;
    final locationAlways = await Permission.locationAlways.status;
    final locationCoarse = await Permission.location.status;

    final hasLocation = locationWhenInUse.isGranted ||
        locationAlways.isGranted ||
        locationCoarse.isGranted;

    return PermissionStatusResult(
      hasCamera: cameraStatus.isGranted,
      hasLocation: hasLocation,
      hasMicrophone: microphoneStatus.isGranted,
    );
  }

  /// Requests Camera, Location, and Microphone permissions.
  static Future<PermissionStatusResult> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    final hasCamera = statuses[Permission.camera]?.isGranted ?? false;
    final hasMicrophone = statuses[Permission.microphone]?.isGranted ?? false;
    final hasLocation = (statuses[Permission.locationWhenInUse]?.isGranted ?? false) ||
        (statuses[Permission.location]?.isGranted ?? false);

    return PermissionStatusResult(
      hasCamera: hasCamera,
      hasLocation: hasLocation,
      hasMicrophone: hasMicrophone,
    );
  }

  /// Opens app settings if user permanently denied permissions.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

