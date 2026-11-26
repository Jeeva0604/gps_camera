import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';

class GpsHudOverlay extends StatelessWidget {
  final Position? position;
  final bool hasGpsFix;
  final bool isLocationEnabled;
  final VoidCallback? onTap;

  const GpsHudOverlay({
    super.key,
    required this.position,
    required this.hasGpsFix,
    this.isLocationEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveColor = !isLocationEnabled
        ? (isDark ? Colors.amberAccent : Colors.amber.shade800)
        : (hasGpsFix
            ? (isDark ? Colors.greenAccent : Colors.green.shade700)
            : (isDark ? Colors.orangeAccent : Colors.orange.shade800));

    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.88);

    final titleColor = !isLocationEnabled
        ? (isDark ? Colors.amberAccent : Colors.amber.shade900)
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    final subColor = !isLocationEnabled
        ? (isDark ? Colors.amber.shade200 : Colors.amber.shade800)
        : (isDark ? Colors.grey.shade300 : const Color(0xFF475569));

    return GestureDetector(
      onTap: !isLocationEnabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: effectiveColor.withValues(alpha: isDark ? 0.45 : 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: !isLocationEnabled
                  ? HugeIcons.strokeRoundedLocationOffline01
                  : (hasGpsFix
                      ? HugeIcons.strokeRoundedLocation01
                      : HugeIcons.strokeRoundedLocation02),
              color: effectiveColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    !isLocationEnabled
                        ? 'Location is Turned Off'
                        : (hasGpsFix && position != null
                            ? '${position!.latitude.toStringAsFixed(5)}°, ${position!.longitude.toStringAsFixed(5)}°'
                            : 'Acquiring GPS fix...'),
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: hasGpsFix ? 'monospace' : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !isLocationEnabled
                        ? 'Tap here to enable GPS location'
                        : (hasGpsFix && position != null
                            ? 'Acc: ±${position!.accuracy.toStringAsFixed(1)}m | Alt: ${position!.altitude.toStringAsFixed(1)}m'
                            : 'Searching for satellites'),
                    style: TextStyle(
                      color: subColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                !isLocationEnabled ? 'OFF' : (hasGpsFix ? 'LIVE' : 'WAIT'),
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
