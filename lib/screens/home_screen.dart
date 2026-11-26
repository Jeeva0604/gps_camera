import 'package:flutter/material.dart';
import 'camera_screen.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  final CameraMode initialMode;

  const HomeScreen({
    super.key,
    this.initialMode = CameraMode.photo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  void _onModeChanged(CameraMode mode) {
    if (_currentMode != mode) {
      setState(() {
        _currentMode = mode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CameraScreen(
      key: ValueKey(_currentMode),
      initialMode: _currentMode,
      onModeChanged: _onModeChanged,
    );
  }
}
