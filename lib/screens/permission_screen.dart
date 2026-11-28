import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/permission_service.dart';
import '../services/update_service.dart';
import '../utils/app_design.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real-time permission states for live tick indicators
  bool _hasCamera = false;
  bool _hasLocation = false;
  bool _hasMicrophone = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _checkCurrentStatuses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentStatuses() async {
    final status = await PermissionService.checkPermissions();
    if (mounted) {
      setState(() {
        _hasCamera = status.hasCamera;
        _hasLocation = status.hasLocation;
        _hasMicrophone = status.hasMicrophone;
      });
    }
  }

  Future<void> _handleRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await PermissionService.requestPermissions();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasCamera = result.hasCamera;
        _hasLocation = result.hasLocation;
        _hasMicrophone = result.hasMicrophone;
      });
    }

    if (result.isGranted) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        final List<String> missing = [];
        if (!result.hasCamera) missing.add('Camera');
        if (!result.hasLocation) missing.add('Location');
        if (!result.hasMicrophone) missing.add('Microphone');

        _errorMessage =
            'Please enable ${missing.join(', ')} to begin taking geotagged photos & videos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppDesign.darkCanvas : AppDesign.lightCanvas;
    final textPrimary =
        isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary;
    final textSecondary =
        isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Ambient decorative background gradient glow
          Positioned(
            top: -120,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppDesign.accent.withValues(
                          alpha: isDark ? 0.25 * _pulseAnimation.value : 0.15,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppDesign.primary.withValues(
                      alpha: isDark ? 0.20 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Interactive Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 28),

                        // Hero Icon with Multi-ring Pulsing Halo
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse ring
                                  Container(
                                    width: 120 + (_pulseAnimation.value * 16),
                                    height: 120 + (_pulseAnimation.value * 16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppDesign.primary.withValues(
                                          alpha: (1.0 - _pulseAnimation.value) *
                                              0.4,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Inner glow circle
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppDesign.primaryGradient,
                                      boxShadow: AppDesign.glowShadow(
                                        AppDesign.primary,
                                        opacity: isDark ? 0.45 : 0.25,
                                      ),
                                    ),
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.asset(
                                          'assets/icon/app_icon.png',
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedLocation01,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 26),

                        // App Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppDesign.primary.withValues(alpha: 0.12),
                            borderRadius: AppDesign.radiusFull,
                            border: Border.all(
                              color: AppDesign.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppDesign.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'QUICK SETUP',
                                style: TextStyle(
                                  color: AppDesign.primaryGlow,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Main Title
                        Text(
                          'Empower Your Camera',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'To stamp accurate satellite maps, live GPS coordinates, and crystal-clear audio onto your media, grant access below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 3 Permission Feature Tiles
                        _buildPermissionCard(
                          icon: HugeIcons.strokeRoundedCamera01,
                          accentColor: const Color(0xFF3B82F6),
                          title: 'Camera Device',
                          description:
                              'Capture ultra-sharp photos & continuous video.',
                          isGranted: _hasCamera,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionCard(
                          icon: HugeIcons.strokeRoundedLocation01,
                          accentColor: AppDesign.accent,
                          title: 'Precise GPS Location',
                          description:
                              'Embed realtime satellite maps, address & coordinates.',
                          isGranted: _hasLocation,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionCard(
                          icon: HugeIcons.strokeRoundedMic01,
                          accentColor: const Color(0xFF8B5CF6),
                          title: 'Microphone & Audio',
                          description:
                              'Record ambient sound synchronized with video.',
                          isGranted: _hasMicrophone,
                          isDark: isDark,
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: AppDesign.radiusMedium,
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedInformationCircle,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient Primary CTA Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius: AppDesign.radiusMedium,
                          boxShadow: AppDesign.glowShadow(AppDesign.primary,
                              opacity: 0.4),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _handleRequest,
                            borderRadius: AppDesign.radiusMedium,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continue & Allow Access',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedArrowRight01,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Settings Fallback link
                      TextButton.icon(
                        onPressed: () => PermissionService.openSettings(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          color: textSecondary,
                          size: 16,
                        ),
                        label: Text(
                          'Open Device App Settings',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required dynamic icon,
    required Color accentColor,
    required String title,
    required String description,
    required bool isGranted,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppDesign.darkCard : Colors.white;
    final borderColor = isGranted
        ? AppDesign.emerald.withValues(alpha: 0.5)
        : (isDark ? AppDesign.darkBorder : AppDesign.lightBorder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppDesign.radiusMedium,
        border: Border.all(color: borderColor, width: isGranted ? 1.5 : 1),
        boxShadow: AppDesign.softShadow(isDark),
      ),
      child: Row(
        children: [
          // Icon Capsule
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppDesign.emerald.withValues(alpha: 0.15)
                  : accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: isGranted ? AppDesign.emerald : accentColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppDesign.darkTextPrimary
                        : AppDesign.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark
                        ? AppDesign.darkTextSecondary
                        : AppDesign.lightTextSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppDesign.emerald.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGranted) ...[
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: AppDesign.emerald,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ready',
                    style: TextStyle(
                      color: AppDesign.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Required',
                    style: TextStyle(
                      color: isDark
                          ? AppDesign.darkTextMuted
                          : AppDesign.lightTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
