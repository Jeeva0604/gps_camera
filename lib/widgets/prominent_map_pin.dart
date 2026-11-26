import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An authentic, classic Google Maps location pin:
/// - Smooth circular bulb with a sharp bottom needle pointer pointing directly at the coordinate.
/// - Dark circular drop shadow underneath the tip.
/// - Solid white outer contrast border for 100% visibility over dark satellite tiles.
/// - Vibrant Google Maps Red fill (`#EA4335`).
/// - Clean round white hole / dot in the center of the head.
class ProminentMapPin extends StatelessWidget {
  final double size;
  final Color pinColor;

  const ProminentMapPin({
    super.key,
    this.size = 36.0,
    this.pinColor = const Color(0xFFEA4335), // Authentic Google Maps Red
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleMapPinPainter(pinColor: pinColor),
      ),
    );
  }
}

class _GoogleMapPinPainter extends CustomPainter {
  final Color pinColor;

  const _GoogleMapPinPainter({required this.pinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Ground contact shadow (projected under the tip)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.96),
        width: w * 0.38,
        height: h * 0.14,
      ),
      shadowPaint,
    );

    // 2. Geometry calculations for classic pin
    // Top circle: center at (cx, cy), radius r
    final cx = w * 0.5;
    final r = w * 0.35;
    final cy = r + (h * 0.04);
    final tip = Offset(cx, h * 0.94);

    // Distance from center to tip
    final d = tip.dy - cy;
    // Tangent angle from tip to circle
    final alpha = math.asin((r / d).clamp(0.0, 1.0));

    // Tangent points on circle
    final leftTangent = Offset(
      cx - (r * math.cos(alpha)),
      cy + (r * math.sin(alpha)),
    );
    final rightTangent = Offset(
      cx + (r * math.cos(alpha)),
      cy + (r * math.sin(alpha)),
    );

    final pinPath = Path();
    pinPath.moveTo(tip.dx, tip.dy);
    pinPath.lineTo(leftTangent.dx, leftTangent.dy);
    pinPath.arcToPoint(
      rightTangent,
      radius: Radius.circular(r),
      largeArc: true,
      clockwise: true,
    );
    pinPath.lineTo(tip.dx, tip.dy);
    pinPath.close();

    // 3. Thick white border for high contrast against satellite tiles
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pinPath, strokePaint);

    // 4. Vibrant Red fill
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // 5. White center hole / inner dot
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.44, holePaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleMapPinPainter oldDelegate) =>
      oldDelegate.pinColor != pinColor;
}
