import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gps_photo_data.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/open_location_code.dart';
import '../services/storage_service.dart';
import '../services/watermark_service.dart';
import '../widgets/gps_minimap_card.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import 'dart:io';
import '../utils/toast_helper.dart';
import 'preview_screen.dart';
import 'video_preview_screen.dart';

enum CameraMode { photo, video }

class CameraScreen extends StatefulWidget {
  final CameraMode initialMode;
  final ValueChanged<CameraMode>? onModeChanged;

  const CameraScreen({
    super.key,
    this.initialMode = CameraMode.photo,
    this.onModeChanged,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraMode _currentMode;
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _processingMessage = '';

  // Video recording state
  bool _isRecordingVideo = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  Position? _currentPosition;
  String? _currentAddress;
  GpsPhotoData? _liveGpsData;
  DateTime? _lastGeocodeTime;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  bool _isLocationEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkLocationStatus();
    _startLocationUpdates();
    _listenToLocationStatus();

    // Check for in-app updates every time the app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    controller?.dispose();
    _positionSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;

    // When the app goes to background or becomes inactive/paused, safely dispose
    // and immediately reset state so build() will not render CameraPreview
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller != null) {
        _isCameraInitialized = false;
        _cameraController = null;
        if (mounted) {
          setState(() {});
        }
        controller.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      UpdateService.checkForUpdate();
      if (_cameraController == null || !_isCameraInitialized) {
        _initializeCamera();
      }
      _checkLocationStatus();
      _startLocationUpdates();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (_cameraController != null) {
        final oldController = _cameraController;
        _cameraController = null;
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
        await oldController?.dispose();
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      if (_selectedCameraIndex >= _cameras.length) {
        _selectedCameraIndex = 0;
      }

      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraController = null;
        });
      }
      ToastHelper.show('Failed to initialize camera: $e');
    }
  }

  void _startLocationUpdates() async {
    // 0. Seed cached data from previous session immediately for instant 0ms HUD rendering
    final cached = await LocationService.getCachedGpsData();
    if (cached != null && mounted && _currentPosition == null) {
      setState(() {
        _currentPosition = Position(
          latitude: cached.latitude,
          longitude: cached.longitude,
          timestamp: cached.timestamp,
          accuracy: cached.accuracy,
          altitude: cached.altitude,
          altitudeAccuracy: 0.0,
          heading: cached.heading ?? 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _liveGpsData = cached;
        _currentAddress = cached.fullAddress;
      });
    }

    // 1. Check last known position from device OS (fast, cached hardware fix)
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        final plusCode =
            OpenLocationCode.encode(lastPos.latitude, lastPos.longitude);
        setState(() {
          _currentPosition = lastPos;
          _liveGpsData = GpsPhotoData(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            altitude: lastPos.altitude,
            accuracy: lastPos.accuracy,
            heading: lastPos.heading,
            timestamp: DateTime.now(),
            plusCode: plusCode,
            locality: _liveGpsData?.locality,
            administrativeArea: _liveGpsData?.administrativeArea,
            country: _liveGpsData?.country,
            countryCode: _liveGpsData?.countryCode,
            postalCode: _liveGpsData?.postalCode,
            street: _liveGpsData?.street,
          );
        });
        _resolveAddressDebounced(lastPos.latitude, lastPos.longitude);
      }
    } catch (_) {}

    // 2. Real-time location stream (continues when stationary)
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.getPositionStream().listen(
      (pos) {
        if (mounted) {
          final plusCode = OpenLocationCode.encode(pos.latitude, pos.longitude);
          setState(() {
            _currentPosition = pos;
            _liveGpsData = GpsPhotoData(
              latitude: pos.latitude,
              longitude: pos.longitude,
              altitude: pos.altitude,
              accuracy: pos.accuracy,
              heading: pos.heading,
              timestamp: DateTime.now(),
              plusCode: plusCode,
              locality: _liveGpsData?.locality,
              administrativeArea: _liveGpsData?.administrativeArea,
              country: _liveGpsData?.country,
              countryCode: _liveGpsData?.countryCode,
              postalCode: _liveGpsData?.postalCode,
              street: _liveGpsData?.street,
            );
          });
          _resolveAddressDebounced(pos.latitude, pos.longitude);
        }
      },
      onError: (_) {},
    );

    // 3. Fast one-shot current position fetch
    try {
      final fastPos = await LocationService.getFastCurrentPosition();
      if (fastPos != null && mounted) {
        final plusCode =
            OpenLocationCode.encode(fastPos.latitude, fastPos.longitude);
        setState(() {
          _currentPosition = fastPos;
          _liveGpsData = GpsPhotoData(
            latitude: fastPos.latitude,
            longitude: fastPos.longitude,
            altitude: fastPos.altitude,
            accuracy: fastPos.accuracy,
            heading: fastPos.heading,
            timestamp: DateTime.now(),
            plusCode: plusCode,
            locality: _liveGpsData?.locality,
            administrativeArea: _liveGpsData?.administrativeArea,
            country: _liveGpsData?.country,
            countryCode: _liveGpsData?.countryCode,
            postalCode: _liveGpsData?.postalCode,
            street: _liveGpsData?.street,
          );
        });
        _resolveAddressDebounced(fastPos.latitude, fastPos.longitude);
      }
    } catch (_) {}
  }

  Future<void> _checkLocationStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() {
        _isLocationEnabled = enabled;
      });
    }
  }

  void _listenToLocationStatus() {
    _serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((status) {
      final enabled = (status == ServiceStatus.enabled);
      if (mounted) {
        setState(() {
          _isLocationEnabled = enabled;
        });
        if (enabled) {
          _startLocationUpdates();
        }
      }
    });
  }

  Future<void> _promptEnableLocation() async {
    final enabled = await LocationService.requestEnableLocation();
    if (enabled && mounted) {
      setState(() {
        _isLocationEnabled = true;
      });
      _startLocationUpdates();
    }
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocationOffline01,
              color: Colors.amberAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Location Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Location service is turned off. Please enable GPS so your photos can be stamped with live satellite maps, accurate coordinates, and address.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _promptEnableLocation();
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              size: 18,
              color: Colors.black,
            ),
            label: const Text('Enable Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAddressDebounced(double lat, double lon) async {
    final now = DateTime.now();
    if (_lastGeocodeTime != null &&
        now.difference(_lastGeocodeTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastGeocodeTime = now;
    try {
      final geo = await LocationService.reverseGeocode(lat, lon);
      final plusCode = OpenLocationCode.encode(lat, lon);
      if (mounted) {
        final updatedData = GpsPhotoData(
          latitude: lat,
          longitude: lon,
          altitude: _currentPosition?.altitude ?? 0.0,
          accuracy: _currentPosition?.accuracy ?? 5.0,
          heading: _currentPosition?.heading,
          timestamp: now,
          locality: geo['locality'] ?? _liveGpsData?.locality,
          administrativeArea: geo['state'] ?? _liveGpsData?.administrativeArea,
          country: geo['country'] ?? _liveGpsData?.country,
          countryCode: geo['countryCode'] ?? _liveGpsData?.countryCode ?? 'IN',
          postalCode: geo['postalCode'] ?? _liveGpsData?.postalCode,
          street: geo['street'] ?? _liveGpsData?.street,
          plusCode: plusCode,
        );
        setState(() {
          _currentAddress =
              geo['displayName'] ?? geo['locality'] ?? updatedData.fullAddress;
          _liveGpsData = updatedData;
        });
        LocationService.saveCachedGpsData(updatedData);
      }
    } catch (_) {}
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras.length < 2 || !_isCameraInitialized) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    final oldController = _cameraController;
    _cameraController = null;
    await oldController?.dispose();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    FlashMode nextMode;
    String toastText;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        toastText = 'Flash: Auto';
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        toastText = 'Flash: On';
        break;
      case FlashMode.always:
      default:
        nextMode = FlashMode.off;
        toastText = 'Flash: Off';
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      if (mounted) {
        setState(() {
          _flashMode = nextMode;
        });
        ToastHelper.show(toastText);
      }
    } catch (_) {
      // If auto or always is not supported by device/lens, toggle to next supported mode
      try {
        final fallbackMode = _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
        await _cameraController!.setFlashMode(fallbackMode);
        if (mounted) {
          setState(() {
            _flashMode = fallbackMode;
          });
          ToastHelper.show(fallbackMode == FlashMode.off ? 'Flash: Off' : 'Flash: On');
        }
      } catch (_) {}
    }
  }

  Future<void> _captureAndStampPhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    // Verify location is enabled before capturing
    final isLocEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocEnabled) {
      if (mounted) {
        setState(() {
          _isLocationEnabled = false;
        });
        _showEnableLocationDialog();
      }
      return;
    }

    setState(() {
      _isCapturing = true;
      _processingMessage = 'Capturing photo...';
    });

    try {
      // 1. Take photo
      final xFile = await _cameraController!.takePicture();
      final photoBytes = await xFile.readAsBytes();

      // 2. Lock GPS Coordinates & Reverse Geocode
      setState(() {
        _processingMessage = 'Acquiring GPS fix & address...';
      });
      final gpsData = await LocationService.getCaptureGpsData();

      // 3. Download high-resolution stitched map snapshot
      setState(() {
        _processingMessage = 'Rendering satellite map snapshot...';
      });
      final mapBytes = await MapService.getMapSnapshot(
        latitude: gpsData.latitude,
        longitude: gpsData.longitude,
        width: 320,
        height: 320,
        zoom: 18,
      );

      // 4. Burn Map and GPS metadata banner onto photo
      setState(() {
        _processingMessage = 'Stamping GPS watermark...';
      });
      final stampedBytes = await WatermarkService.stampPhoto(
        photoBytes: photoBytes,
        mapBytes: mapBytes,
        gpsData: gpsData,
      );

      // 5. Save to temp file and route to preview
      final stampedFile = await StorageService.saveToTempFile(stampedBytes);

      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            photoFile: stampedFile,
            gpsData: gpsData,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
      ToastHelper.show('Capture failed: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isRecordingVideo) {
      return;
    }

    // Verify location is enabled before recording
    final isLocEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocEnabled) {
      if (mounted) {
        setState(() {
          _isLocationEnabled = false;
        });
        _showEnableLocationDialog();
      }
      return;
    }

    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecordingVideo = true;
        _recordSeconds = 0;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    } catch (e) {
      ToastHelper.show('Failed to start recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !_isRecordingVideo) {
      return;
    }

    _recordTimer?.cancel();
    setState(() {
      _isRecordingVideo = false;
      _isCapturing = true;
      _processingMessage = 'Finalizing video recording...';
    });

    try {
      final xFile = await controller.stopVideoRecording();
      File videoFile = File(xFile.path);

      // Lock current GPS position & address for metadata
      GpsPhotoData? gpsData;
      try {
        gpsData = await LocationService.getCaptureGpsData();
      } catch (_) {
        gpsData = _liveGpsData;
      }

      // If we have GPS data, render the GPS location tile and burn it into the video
      if (gpsData != null) {
        try {
          setState(() {
            _processingMessage = 'Rendering GPS location tile...';
          });

          // Query the exact resolution and orientation of the recorded video
          final videoDims =
              await StorageService.getVideoDimensions(videoFile.path);
          final vWidth = videoDims['width'] ?? 1080;
          final vHeight = videoDims['height'] ?? 1920;

          final mapBytes = await MapService.getMapSnapshot(
            latitude: gpsData.latitude,
            longitude: gpsData.longitude,
            width: 320,
            height: 320,
            zoom: 18,
          );

          final cardPngBytes =
              await WatermarkService.renderFullFrameVideoOverlayPng(
            mapBytes: mapBytes,
            gpsData: gpsData,
            frameWidth: vWidth,
            frameHeight: vHeight,
          );

          final cardFile = await StorageService.saveToTempFile(cardPngBytes);

          setState(() {
            _processingMessage = 'Burning GPS location tile onto video...';
          });

          final stampedVideo = await StorageService.overlayWatermarkOnVideo(
            videoPath: videoFile.path,
            overlayPngPath: cardFile.path,
          );

          if (stampedVideo != null && await stampedVideo.exists()) {
            videoFile = stampedVideo;
          }
        } catch (overlayError) {
          debugPrint('Watermark overlay error: $overlayError');
        }
      }

      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _recordSeconds = 0;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            videoFile: videoFile,
            gpsData: gpsData,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _recordSeconds = 0;
        });
      }
      ToastHelper.show('Failed to save video: $e');
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _switchMode(CameraMode mode) {
    if (_isRecordingVideo) {
      ToastHelper.show('Please stop recording before switching modes.');
      return;
    }
    if (_currentMode != mode) {
      setState(() {
        _currentMode = mode;
      });
      widget.onModeChanged?.call(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    if (!_isCameraInitialized ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder
          Center(
            child: CameraPreview(controller),
          ),

          // 2. Top Bar: Controls & Real-time GPS HUD
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flash Toggle
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            HugeIcon(
                              icon: _flashMode == FlashMode.off
                                  ? HugeIcons.strokeRoundedFlashOff
                                  : HugeIcons.strokeRoundedFlash,
                              color: _flashMode == FlashMode.off
                                  ? (isDark
                                      ? Colors.white70
                                      : const Color(0xFF0F172A))
                                  : (_flashMode == FlashMode.always
                                      ? Colors.amberAccent
                                      : Colors.amber),
                              size: 20,
                            ),
                            if (_flashMode == FlashMode.auto)
                              Positioned(
                                right: -7,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.5, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'A',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            if (_flashMode == FlashMode.always)
                              Positioned(
                                right: -8,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.5, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ON',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        'GPS CAMERA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Right Controls: Theme Toggle & Camera Switcher
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme Mode Switch Option
                          IconButton(
                            tooltip:
                                isDark ? 'Switch to Light' : 'Switch to Dark',
                            onPressed: () {
                              ThemeService.instance.toggleTheme();
                              ToastHelper.show(
                                ThemeService.instance.isDarkMode
                                    ? 'Dark mode enabled'
                                    : 'Light mode enabled',
                              );
                            },
                            icon: HugeIcon(
                              icon: isDark
                                  ? HugeIcons.strokeRoundedSun01
                                  : HugeIcons.strokeRoundedMoon01,
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF0284C7),
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Camera Switcher
                          IconButton(
                            onPressed: _toggleCameraLens,
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCameraRotated01,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Recording Timer Badge in Video Mode
                if (_isRecordingVideo)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_recordSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 3. Floating Live GPS & Minimap Card (viewfinder overlay above shutter)
          Positioned(
            bottom: 124,
            left: 0,
            right: 0,
            child: GpsMinimapCard(
              position: _currentPosition,
              hasGpsFix: _currentPosition != null,
              gpsData: _liveGpsData,
              address: _currentAddress,
              isLocationEnabled: _isLocationEnabled,
              onEnableLocation: _promptEnableLocation,
            ),
          ),

          // 4. Bottom Shutter Bar ("take photo place")
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prominent Enable Location Pill Button above Shutter
                  if (!_isLocationEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: _promptEnableLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedLocationOffline01,
                                color: Colors.black,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Location is Off • Tap to Enable',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Mode Selector Tabs (Photo vs Video)
                  if (!_isRecordingVideo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Photo Mode Tab
                            GestureDetector(
                              onTap: () => _switchMode(CameraMode.photo),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _currentMode == CameraMode.photo
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedCamera01,
                                      size: 15,
                                      color: _currentMode == CameraMode.photo
                                          ? Colors.black
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'PHOTO',
                                      style: TextStyle(
                                        color: _currentMode == CameraMode.photo
                                            ? Colors.black
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Video Mode Tab
                            GestureDetector(
                              onTap: () => _switchMode(CameraMode.video),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _currentMode == CameraMode.video
                                      ? Colors.redAccent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedVideo01,
                                      size: 16,
                                      color: _currentMode == CameraMode.video
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'VIDEO',
                                      style: TextStyle(
                                        color: _currentMode == CameraMode.video
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Shutter Button (Adaptive for Photo vs Video)
                  GestureDetector(
                    onTap: _isCapturing
                        ? null
                        : (_currentMode == CameraMode.photo
                            ? _captureAndStampPhoto
                            : (_isRecordingVideo
                                ? _stopVideoRecording
                                : _startVideoRecording)),
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentMode == CameraMode.video
                              ? Colors.redAccent
                              : Colors.white,
                          width: 4,
                        ),
                        color: (_currentMode == CameraMode.video
                                ? Colors.redAccent
                                : Colors.white)
                            .withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentMode == CameraMode.video
                              ? Colors.redAccent
                              : Colors.white,
                          shape: _isRecordingVideo
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: _isRecordingVideo
                              ? BorderRadius.circular(8)
                              : null,
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: _currentMode == CameraMode.video
                                ? (_isRecordingVideo
                                    ? HugeIcons.strokeRoundedStop
                                    : HugeIcons.strokeRoundedVideo01)
                                : HugeIcons.strokeRoundedCamera01,
                            color: _currentMode == CameraMode.video
                                ? Colors.white
                                : Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Stamping Loading Indicator Overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 16),
                      Text(
                        _processingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
