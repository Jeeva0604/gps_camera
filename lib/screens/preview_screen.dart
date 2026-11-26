import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gps_photo_data.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../utils/toast_helper.dart';

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
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPS Camera',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'GPS & Location Metadata',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(widget.gpsData.latitude,
                              widget.gpsData.longitude),
                          initialZoom: 18.0,
                          minZoom: 4.0,
                          maxZoom: 20.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                            userAgentPackageName: 'com.jera.gps_camera',
                            maxNativeZoom: 18,
                            fallbackUrl:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            errorTileCallback: (tile, error, stackTrace) {
                              debugPrint('Map tile error: $error');
                            },
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(widget.gpsData.latitude,
                                    widget.gpsData.longitude),
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.redAccent,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMetaTile('Location',
                      '${widget.gpsData.flagEmoji} ${widget.gpsData.titleLocation}',
                      isDark: isDark),
                  _buildMetaTile('Detailed Address (Plus Code)',
                      widget.gpsData.detailedAddressWithPlusCode,
                      isDark: isDark),
                  _buildMetaTile('Coordinates', widget.gpsData.formattedLatLong,
                      isDark: isDark),
                  _buildMetaTile(
                      'Timestamp', widget.gpsData.formattedDateTimeWithGmt,
                      isDark: isDark),
                  _buildMetaTile('Altitude / Accuracy',
                      '${widget.gpsData.altitude.toStringAsFixed(1)}m (±${widget.gpsData.accuracy.toStringAsFixed(1)}m)',
                      isDark: isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaTile(String label, String value, {bool isDark = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Stamped Photo Preview',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'View Metadata',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: isDark ? Colors.cyanAccent : const Color(0xFF0284C7),
                size: 20,
              ),
            ),
            onPressed: _showMetadataBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Zoomable / Pannable Stamped Image
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.photoFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Modern Floating Action Dock
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: _buildModernBottomBar(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Retake Button
              _buildDockIconButton(
                icon: Icons.refresh_rounded,
                label: 'Retake',
                onTap: () => Navigator.of(context).pop(),
                isDark: isDark,
              ),
              const SizedBox(width: 6),

              // Map & Info Button
              _buildDockIconButton(
                icon: Icons.map_outlined,
                label: 'Map Info',
                onTap: _showMetadataBottomSheet,
                isDark: isDark,
                highlightColor:
                    isDark ? Colors.cyanAccent : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 6),

              // Share Button
              _buildDockIconButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: _sharePhoto,
                isDark: isDark,
              ),
              const SizedBox(width: 10),

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

  Widget _buildDockIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? highlightColor,
  }) {
    final iconColor =
        highlightColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final textColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSaved
                  ? [const Color(0xFF059669), const Color(0xFF10B981)]
                  : [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: (isSaved
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB))
                    .withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
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
                  Icon(
                    isSaved
                        ? Icons.check_circle_rounded
                        : Icons.save_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isSaving ? 'Saving...' : (isSaved ? 'Saved' : 'Save Photo'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
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
