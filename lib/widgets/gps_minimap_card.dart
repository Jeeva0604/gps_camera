import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/gps_photo_data.dart';
import '../services/open_location_code.dart';
import 'prominent_map_pin.dart';

class GpsMinimapCard extends StatefulWidget {
  final Position? position;
  final bool hasGpsFix;
  final GpsPhotoData? gpsData;
  final String? address;
  final bool isLocationEnabled;
  final VoidCallback? onEnableLocation;

  const GpsMinimapCard({
    super.key,
    required this.position,
    required this.hasGpsFix,
    this.gpsData,
    this.address,
    this.isLocationEnabled = true,
    this.onEnableLocation,
  });

  @override
  State<GpsMinimapCard> createState() => _GpsMinimapCardState();
}

class _GpsMinimapCardState extends State<GpsMinimapCard>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant GpsMinimapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pos = widget.position;
    if (pos != null) {
      if (oldWidget.position == null ||
          oldWidget.position!.latitude != pos.latitude ||
          oldWidget.position!.longitude != pos.longitude) {
        try {
          _mapController.move(
            LatLng(pos.latitude, pos.longitude),
            18.0,
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatDateTimeWithGmt(DateTime time) {
    final base = DateFormat('EEEE, MM/dd/yyyy hh:mm a').format(time);
    final offset = time.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$base GMT $sign$hours:$minutes';
  }

  void _openExpandedMap(BuildContext context, Position pos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCamera01,
                                size: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GPS Camera',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color:
                      isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(pos.latitude, pos.longitude),
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
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 38,
                            height: 38,
                            child: const ProminentMapPin(size: 38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lat ${pos.latitude.toStringAsFixed(6)}° Long ${pos.longitude.toStringAsFixed(6)}°',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFFACC15)
                              : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (widget.gpsData != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.gpsData!.detailedAddressWithPlusCode,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontSize: 12),
                          maxLines: 4,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.position;
    final hasFix = widget.hasGpsFix && pos != null;
    final data = widget.gpsData;

    final isLocEnabled = widget.isLocationEnabled;

    // Line 3: Detailed Address with Plus Code
    final plusCode = data?.resolvedPlusCode ??
        (hasFix ? OpenLocationCode.encode(pos.latitude, pos.longitude) : '...');

    // Line 1: Title (Locality, State, Country)
    final titleText = !isLocEnabled
        ? 'Location Service is Off'
        : (data != null && data.hasAddress
            ? data.titleLocation
            : (widget.address != null && widget.address!.isNotEmpty
                ? widget.address!
                : (hasFix
                    ? (data?.titleLocation != null &&
                            data!.titleLocation != 'Location Details'
                        ? data.titleLocation
                        : '$plusCode (Locating Area...)')
                    : 'Searching Satellites...')));

    // Line 2: Flag Emoji
    final flag = data?.flagEmoji ?? '🇮🇳';

    // Line 3: Detailed Address with Plus Code
    final detailAddr = !isLocEnabled
        ? 'Tap here to enable device GPS'
        : (data != null && data.hasAddress
            ? data.detailedAddressWithPlusCode
            : (hasFix
                ? (widget.address != null && widget.address!.isNotEmpty
                    ? '$plusCode, ${widget.address}'
                    : '$plusCode • Lat ${pos.latitude.toStringAsFixed(4)}°, Long ${pos.longitude.toStringAsFixed(4)}°')
                : 'Waiting for GPS position...'));

    // Line 4: Lat/Long
    final latLongText = !isLocEnabled
        ? 'GPS is disabled on device'
        : (hasFix
            ? 'Lat ${pos.latitude.toStringAsFixed(6)}° Long ${pos.longitude.toStringAsFixed(6)}°'
            : 'Lat --.------° Long --.------°');

    // Line 5: Timestamp
    final timeText = _formatDateTimeWithGmt(_currentTime);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // App name badge positioned above the location card
        Padding(
          padding: const EdgeInsets.only(right: 18, bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xE81E242C) : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        size: 11,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'GPS Camera',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main Location Card Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE8242424) : const Color(0xF5FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Left Square Satellite Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    child: hasFix
                        ? GestureDetector(
                            onTap: () => _openExpandedMap(context, pos),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Live ArcGIS Satellite Tile View
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter:
                                        LatLng(pos.latitude, pos.longitude),
                                    initialZoom: 18.0,
                                    minZoom: 10.0,
                                    maxZoom: 20.0,
                                    interactionOptions:
                                        const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                      userAgentPackageName:
                                          'com.jera.gps_camera',
                                      maxNativeZoom: 18,
                                      fallbackUrl:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      errorTileCallback:
                                          (tile, error, stackTrace) {
                                        debugPrint(
                                            'Minimap tile error: $error');
                                      },
                                    ),
                                  ],
                                ),

                                // Google Style Red Pin at Center
                                const Center(
                                  child: ProminentMapPin(size: 28),
                                ),

                                // "Google" text logo at bottom-left
                                const Positioned(
                                  bottom: 3,
                                  left: 5,
                                  child: Text(
                                    'Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 3,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: !widget.isLocationEnabled
                                ? GestureDetector(
                                    onTap: widget.onEnableLocation,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons.strokeRoundedLocationOffline01,
                                          color: Colors.amberAccent,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amberAccent,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'ENABLE',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedSatellite01,
                                        color: Colors.amberAccent,
                                        size: 24,
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Waiting GPS',
                                        style: TextStyle(
                                            color: Colors.white60, fontSize: 8),
                                      ),
                                    ],
                                  ),
                          ),
                  ),
                ),

                const SizedBox(width: 10),

                // 2. Right Text Column
                Expanded(
                  child: GestureDetector(
                    onTap: !widget.isLocationEnabled
                        ? widget.onEnableLocation
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Line 1: Locality, State, Country (Bold White or Amber if disabled)
                        Text(
                          titleText,
                          style: TextStyle(
                            color: !widget.isLocationEnabled
                                ? (isDark
                                    ? Colors.amberAccent
                                    : Colors.amber.shade900)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 1),

                        // Line 2: Country Flag Emoji (e.g. 🇮🇳)
                        Text(
                          flag,
                          style: const TextStyle(fontSize: 18.5),
                        ),

                        const SizedBox(height: 2),

                        // Line 3: Detailed Address with Plus Code
                        Text(
                          detailAddr,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade200
                                : const Color(0xFF334155),
                            fontSize: 11.0,
                            height: 1.25,
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 3),

                        // Line 4: Formatted Lat/Long
                        Text(
                          latLongText,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),

                        const SizedBox(height: 2),

                        // Line 5: Formatted Timestamp with Day and GMT
                        Text(
                          timeText,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF64748B),
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
