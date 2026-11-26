import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/update_service.dart';
import 'camera_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  Future<void> _handleRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await PermissionService.requestPermissions();

    setState(() {
      _isLoading = false;
    });

    if (result.isGranted) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
    } else {
      setState(() {
        _errorMessage =
            'Camera and Location permissions are required to take photos and tag them with GPS data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: isDark ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: isDark ? 0.4 : 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'GPS Camera Access',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'To capture photos with embedded GPS coordinates, address, and live map snapshots, this app requires camera and location permissions.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _buildFeatureRow(
                icon: Icons.camera_alt_outlined,
                title: 'Camera Access',
                subtitle: 'Capture high-resolution photos directly in-app.',
                isDark: isDark,
              ),
              const SizedBox(height: 18),
              _buildFeatureRow(
                icon: Icons.my_location_outlined,
                title: 'Location (GPS) Access',
                subtitle: 'Record exact latitude, longitude, and map snippets.',
                isDark: isDark,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Grant Permissions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => PermissionService.openSettings(),
                child: Text(
                  'Open Device Settings',
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF64748B),
                      fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isDark ? Colors.cyanAccent : const Color(0xFF0284C7),
              size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF64748B),
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
