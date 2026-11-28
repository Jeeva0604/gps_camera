import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/permission_service.dart';
import '../services/update_service.dart';
import '../utils/app_design.dart';
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
        isDark ? AppDesign.darkCanvas : AppDesign.lightCanvas;
    final primaryTextColor =
        isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary;
    final subtitleColor =
        isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Modern Glass Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppDesign.glowShadow(AppDesign.primary,
                              opacity: 0.35),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPS CAMERA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: primaryTextColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppDesign.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SATELLITE SYNC READY',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppDesign.darkTextMuted
                                      : AppDesign.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppDesign.darkBorder
                              : AppDesign.lightBorder,
                        ),
                        boxShadow: AppDesign.softShadow(isDark),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSettings01,
                        color: primaryTextColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Hero Feature Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: AppDesign.glassCardGradient(isDark),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : const Color(0xFF64748B)
                                    .withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // App Logo with glowing ring
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppDesign.glowShadow(AppDesign.primary,
                                  opacity: 0.3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
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

                          const SizedBox(height: 16),

                          Text(
                            'GPS Map Camera',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'Capture geotagged photos & Full HD videos with live satellite maps, coordinates, elevation, and timestamp stamping.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: subtitleColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Quick feature pill chips
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPillChip(
                                isDark: isDark,
                                icon: HugeIcons.strokeRoundedLocation01,
                                label: 'Satellite Map',
                              ),
                              _buildPillChip(
                                isDark: isDark,
                                icon: HugeIcons.strokeRoundedClock01,
                                label: 'Live Timestamp',
                              ),
                              _buildPillChip(
                                isDark: isDark,
                                icon: HugeIcons.strokeRoundedLocation03,
                                label: 'GPS Geodata',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                        child: Text(
                          'SELECT CAPTURE MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppDesign.darkTextMuted
                                : AppDesign.lightTextMuted,
                          ),
                        ),
                      ),
                    ),

                    // Mode 1: Photo Tile
                    _buildCaptureTile(
                      title: 'Photo Capture',
                      subtitle:
                          'Stamp high-resolution stills with live satellite view & coordinates',
                      icon: HugeIcons.strokeRoundedCamera01,
                      gradient: AppDesign.primaryGradient,
                      badgeText: 'INSTANT STAMP',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      subtitleColor: subtitleColor,
                      onTap: () => _navigateToCamera(CameraMode.photo),
                    ),

                    const SizedBox(height: 14),

                    // Mode 2: Video Tile
                    _buildCaptureTile(
                      title: 'Video Recording',
                      subtitle:
                          'Record stabilized Full HD video with dynamic GPS overlay & audio',
                      icon: HugeIcons.strokeRoundedVideo01,
                      gradient: AppDesign.videoGradient,
                      badgeText: 'FULL HD RECORD',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      subtitleColor: subtitleColor,
                      onTap: () => _navigateToCamera(CameraMode.video),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip({
    required bool isDark,
    required dynamic icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            color: AppDesign.primaryGlow,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppDesign.darkTextSecondary
                  : AppDesign.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureTile({
    required String title,
    required String subtitle,
    required dynamic icon,
    required LinearGradient gradient,
    required String badgeText,
    required bool isDark,
    required Color primaryTextColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? AppDesign.darkCard : AppDesign.lightCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: gradient.colors.first.withValues(alpha: 0.15),
        highlightColor: gradient.colors.first.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
              width: 1.2,
            ),
            boxShadow: AppDesign.softShadow(isDark),
          ),
          child: Row(
            children: [
              // Vibrant Gradient Icon Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow:
                      AppDesign.glowShadow(gradient.colors.first, opacity: 0.3),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: Colors.white,
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                gradient.colors.first.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: gradient.colors.first,
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
                        height: 1.35,
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
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: primaryTextColor.withValues(alpha: 0.7),
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
