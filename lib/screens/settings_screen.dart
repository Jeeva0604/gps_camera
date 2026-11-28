import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/review_service.dart';
import '../services/template_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../utils/app_design.dart';
import '../utils/toast_helper.dart';
import 'in_app_web_view_screen.dart';
import 'template_select_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '2';
  static const String _supportEmail = 'hellojeralabs@gmail.com';
  static const String _packageName = 'com.jera.gps_camera';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageName';
  static const String _privacyPolicyUrl =
      'https://jeralabs.netlify.app/privacy';
  static const String _termsUrl = 'https://jeralabs.netlify.app/terms';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _contactSupport() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'GPS Camera Support & Feedback (v$_appVersion)',
        'body':
            'Hello GPS Camera Team,\n\nDevice: ${Platform.operatingSystem}\nApp Version: $_appVersion+$_buildNumber\n\nIssue / Feedback:\n',
      },
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ToastHelper.show(
            'Could not open email client. Contact: $_supportEmail');
      }
    } catch (_) {
      ToastHelper.show('Support email: $_supportEmail');
    }
  }

  Future<void> _shareApp() async {
    const shareText =
        'Check out GPS Camera! Capture photos & videos with live satellite map stamping, GPS coordinates, address, and timestamp:\n$_playStoreUrl';
    try {
      await Share.share(shareText,
          subject: 'GPS Camera with Live Map & Watermark');
    } catch (e) {
      ToastHelper.show('Failed to share app: $e');
    }
  }

  Future<void> _rateUs() async {
    await ReviewService.requestReviewOrOpenStore();
  }

  Future<void> _checkForUpdate() async {
    ToastHelper.show('Checking for updates...');
    await UpdateService.checkForUpdate(showFeedbackOnLatest: true);
  }

  void _openInAppWebView(String title, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppWebViewScreen(title: title, url: url),
      ),
    );
  }

  void _showThemeDialog() {
    final currentMode = ThemeService.instance.themeMode;
    final isDark = ThemeService.instance.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppDesign.darkCard : AppDesign.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Choose Theme',
          style: TextStyle(
            color:
                isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              title: 'System Default',
              subtitle: 'Match device settings',
              icon: HugeIcons.strokeRoundedSettings01,
              selected: currentMode == ThemeMode.system,
              onTap: () {
                ThemeService.instance.setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
                setState(() {});
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              title: 'Light Theme',
              subtitle: 'Clean white appearance',
              icon: HugeIcons.strokeRoundedSun01,
              selected: currentMode == ThemeMode.light,
              onTap: () {
                ThemeService.instance.setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
                setState(() {});
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              title: 'Dark Theme',
              subtitle: 'Comfortable in low light',
              icon: HugeIcons.strokeRoundedMoon01,
              selected: currentMode == ThemeMode.dark,
              onTap: () {
                ThemeService.instance.setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
                setState(() {});
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected
          ? AppDesign.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppDesign.primary.withValues(alpha: 0.2)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HugeIcon(
          icon: icon,
          size: 20,
          color: selected
              ? AppDesign.primaryGlow
              : (isDark
                  ? AppDesign.darkTextSecondary
                  : AppDesign.lightTextSecondary),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppDesign.darkTextMuted : AppDesign.lightTextMuted,
          fontSize: 12,
        ),
      ),
      trailing: selected
          ? const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: AppDesign.primaryGlow,
              size: 22,
            )
          : null,
    );
  }

  String _getThemeSubtitle() {
    switch (ThemeService.instance.themeMode) {
      case ThemeMode.system:
        return 'System default (${ThemeService.instance.isDarkMode ? 'Dark' : 'Light'})';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;
        final backgroundColor =
            isDark ? AppDesign.darkCanvas : AppDesign.lightCanvas;
        final cardColor = isDark ? AppDesign.darkCard : AppDesign.lightCard;
        final primaryTextColor =
            isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary;
        final secondaryTextColor =
            isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;
        final borderColor =
            isDark ? AppDesign.darkBorder : AppDesign.lightBorder;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppDesign.darkSurface : AppDesign.lightSurface,
            elevation: 0,
            leading: IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: primaryTextColor,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // Header Profile / App Branding Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppDesign.glassCardGradient(isDark),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor),
                    boxShadow: AppDesign.softShadow(isDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppDesign.glowShadow(AppDesign.primary,
                              opacity: 0.25),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Image.asset(
                              'assets/icon/splash_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPS Map Camera',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Geotag photos & Full HD videos with GPS',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Appearance Section
                _buildSectionHeader('APPEARANCE & TEMPLATES', secondaryTextColor),
                const SizedBox(height: 8),
                _buildCardGroup(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildSettingsTile(
                      title: 'Watermark Template',
                      subtitle: TemplateService.instance.currentTemplate.displayName,
                      icon: HugeIcons.strokeRoundedLocation01,
                      iconColor: TemplateService.instance.currentTemplate.accentColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TemplateSelectScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      title: 'Theme',
                      subtitle: _getThemeSubtitle(),
                      icon: isDark
                          ? HugeIcons.strokeRoundedMoon01
                          : HugeIcons.strokeRoundedSun01,
                      iconColor: isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF0284C7),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: _showThemeDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Support & Engagement Section
                _buildSectionHeader('SUPPORT & ENGAGEMENT', secondaryTextColor),
                const SizedBox(height: 8),
                _buildCardGroup(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildSettingsTile(
                      title: 'Contact & Support',
                      subtitle: _supportEmail,
                      icon: HugeIcons.strokeRoundedMail01,
                      iconColor: const Color(0xFF06B6D4),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: _contactSupport,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      title: 'Share App',
                      subtitle: 'Recommend GPS Camera to your friends',
                      icon: HugeIcons.strokeRoundedShare01,
                      iconColor: const Color(0xFF3B82F6),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: _shareApp,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      title: 'Rate Us',
                      subtitle: 'Leave your review on Google Play Store',
                      icon: HugeIcons.strokeRoundedStar,
                      iconColor: const Color(0xFFF59E0B),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: _rateUs,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      title: 'Check for Updates',
                      subtitle: 'Ensure you have the latest features & fixes',
                      icon: HugeIcons.strokeRoundedRefresh,
                      iconColor: const Color(0xFF10B981),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: _checkForUpdate,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Legal Section
                _buildSectionHeader('LEGAL & POLICIES', secondaryTextColor),
                const SizedBox(height: 8),
                _buildCardGroup(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildSettingsTile(
                      title: 'Privacy Policy',
                      subtitle: 'How we respect and protect your data',
                      icon: HugeIcons.strokeRoundedShield01,
                      iconColor: const Color(0xFF8B5CF6),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: () => _openInAppWebView(
                          'Privacy Policy', _privacyPolicyUrl),
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      title: 'Terms & Conditions',
                      subtitle: 'Terms of service and usage guidelines',
                      icon: HugeIcons.strokeRoundedFile01,
                      iconColor: const Color(0xFFEC4899),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDark: isDark,
                      onTap: () =>
                          _openInAppWebView('Terms & Conditions', _termsUrl),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // App Version Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'GPS Camera v$_appVersion ($_buildNumber)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 16,
      color: borderColor,
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required dynamic icon,
    required Color iconColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: secondaryTextColor.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
