import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/permission_service.dart';
import '../services/update_service.dart';
import 'camera_screen.dart';
import 'permission_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
      _verifyPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPermissions();
    }
  }

  Future<void> _verifyPermissions() async {
    final status = await PermissionService.checkPermissions();
    if (!status.isGranted && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PermissionScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToCamera(CameraMode mode) async {
    final status = await PermissionService.checkPermissions();
    if (!status.isGranted && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PermissionScreen()),
        (route) => false,
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(initialMode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Theme Toggle
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GPS CAMERA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          color: primaryTextColor,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // App Logo Container with Glow / Border
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/icon/splash_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'GPS Map Camera',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Descriptive Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Capture geotagged photos and high-definition videos with live satellite maps, precise GPS coordinates, address, and timestamp watermarks.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: subtitleColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // 2 Tiles: Photo & Video
                    _buildModeTile(
                      context: context,
                      title: 'Photo',
                      subtitle: 'Snap photos with live GPS map watermark',
                      icon: HugeIcons.strokeRoundedCamera01,
                      accentColor: Colors.blueAccent,
                      badgeText: 'GEOTAG',
                      isDark: isDark,
                      cardColor: cardColor,
                      primaryTextColor: primaryTextColor,
                      subtitleColor: subtitleColor,
                      onTap: () => _navigateToCamera(CameraMode.photo),
                    ),

                    const SizedBox(height: 18),

                    _buildModeTile(
                      context: context,
                      title: 'Video',
                      subtitle: 'Record video with location timestamp overlay',
                      icon: HugeIcons.strokeRoundedVideo01,
                      accentColor: const Color(0xFFEF4444),
                      badgeText: 'HD RECORD',
                      isDark: isDark,
                      cardColor: cardColor,
                      primaryTextColor: primaryTextColor,
                      subtitleColor: subtitleColor,
                      onTap: () => _navigateToCamera(CameraMode.video),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required dynamic icon,
    required Color accentColor,
    required String badgeText,
    required bool isDark,
    required Color cardColor,
    required Color primaryTextColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: accentColor.withValues(alpha: 0.15),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Tile Icon Container
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: accentColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Forward Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: primaryTextColor.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
