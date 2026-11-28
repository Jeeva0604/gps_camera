import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gps_photo_data.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../utils/app_design.dart';
import '../utils/toast_helper.dart';
import '../widgets/prominent_map_pin.dart';

class PreviewScreen extends StatefulWidget {
  final File photoFile;
  final GpsPhotoData gpsData;

  const PreviewScreen({
    super.key,
    required this.photoFile,
    required this.gpsData,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveToGallery() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    final success = await StorageService.saveToGallery(widget.photoFile);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = success;
    });

    if (success) {
      ToastHelper.show('Photo saved to Downloads folder!');
      ReviewService.requestReviewAfterSave();
    } else {
      ToastHelper.show('Failed to save photo to Downloads.');
    }
  }

  Future<void> _sharePhoto() async {
    await Share.shareXFiles(
      [XFile(widget.photoFile.path)],
      text:
          'GPS Photo captured at ${widget.gpsData.formattedCoordinates} - ${widget.gpsData.fullAddress}',
    );
  }

  void _showMetadataBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppDesign.darkSurface : Colors.white;
    final textPrimary =
        isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary;
    final textSecondary =
        isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppDesign.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location Snapshot',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Embedded Photo Geodata',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: textSecondary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mini Map snapshot inside sheet
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                widget.gpsData.latitude,
                                widget.gpsData.longitude,
                              ),
                              initialZoom: 17.5,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'com.jera.gps_camera',
                                maxNativeZoom: 18,
                                fallbackUrl:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                            ],
                          ),
                          const Center(
                            child: ProminentMapPin(size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildMetadataTile(
                    label: 'Coordinates',
                    value: widget.gpsData.formattedCoordinates,
                    icon: HugeIcons.strokeRoundedLocation01,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataTile(
                    label: 'Address',
                    value: widget.gpsData.fullAddress,
                    icon: HugeIcons.strokeRoundedFlag01,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataTile(
                    label: 'Captured Timestamp',
                    value: widget.gpsData.formattedDateTimeWithGmt,
                    icon: HugeIcons.strokeRoundedTime02,
                    isDark: isDark,
                  ),
                  if (widget.gpsData.altitude != 0.0) ...[
                    const SizedBox(height: 8),
                    _buildMetadataTile(
                      label: 'Altitude',
                      value:
                          '${widget.gpsData.altitude.toStringAsFixed(1)} m Above Sea Level',
                      icon: HugeIcons.strokeRoundedSatellite01,
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataTile({
    required String label,
    required String value,
    required dynamic icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkCard : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            size: 18,
            color: AppDesign.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppDesign.darkTextMuted
                        : AppDesign.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppDesign.darkTextPrimary
                        : AppDesign.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppDesign.darkCanvas : AppDesign.lightCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Center(
            child: _buildTopGlassButton(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: AppDesign.radiusFull,
            border: Border.all(
              color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppDesign.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STAMPED PHOTO',
                style: TextStyle(
                  color: isDark
                      ? AppDesign.darkTextPrimary
                      : AppDesign.lightTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: _buildTopGlassButton(
                icon: HugeIcons.strokeRoundedInformationCircle,
                onTap: _showMetadataBottomSheet,
                isDark: isDark,
                highlightColor: AppDesign.accent,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zoomable / Pannable Stamped Image with Modern Card Frame
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.6 : 0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        widget.photoFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Redesigned Glassmorphic Floating Action Dock
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: _buildModernBottomBar(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGlassButton({
    required dynamic icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? highlightColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
        ),
        boxShadow: AppDesign.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 17,
              color: highlightColor ??
                  (isDark
                      ? AppDesign.darkTextPrimary
                      : AppDesign.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomBar(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppDesign.darkCard.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Retake Button
              _buildDockButton(
                icon: HugeIcons.strokeRoundedRefresh,
                label: 'Retake',
                onTap: () => Navigator.of(context).pop(),
                isDark: isDark,
              ),
              const SizedBox(width: 8),

              // Map & Info Button
              _buildDockButton(
                icon: HugeIcons.strokeRoundedLocation01,
                label: 'Geodata',
                onTap: _showMetadataBottomSheet,
                isDark: isDark,
                accentColor: AppDesign.accent,
              ),
              const SizedBox(width: 8),

              // Share Button
              _buildDockButton(
                icon: HugeIcons.strokeRoundedShare01,
                label: 'Share',
                onTap: _sharePhoto,
                isDark: isDark,
              ),
              const SizedBox(width: 12),

              // Hero Save Button
              Expanded(
                child: _buildModernSaveButton(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? accentColor,
  }) {
    final iconColor = accentColor ??
        (isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary);
    final textColor =
        isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSaveButton(bool isDark) {
    final bool isSaved = _isSaved;
    final bool isSaving = _isSaving;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isSaving || isSaved) ? null : _saveToGallery,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 50,
          decoration: BoxDecoration(
            gradient: isSaved
                ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  )
                : AppDesign.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppDesign.glowShadow(
              isSaved ? AppDesign.emerald : AppDesign.primary,
              opacity: 0.45,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  HugeIcon(
                    icon: isSaved
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedDownload01,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  isSaving ? 'Saving...' : (isSaved ? 'Saved' : 'Save Photo'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
