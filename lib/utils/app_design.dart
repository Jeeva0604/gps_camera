import 'package:flutter/material.dart';

/// Centralized modern design tokens, gradients, glass effects, and shadows
/// for the redesigned GPS Map Camera application.
class AppDesign {
  // Vibrant accents
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryGlow = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF06B6D4); // Cyan
  static const Color emerald = Color(0xFF10B981); // Emerald Green
  static const Color amber = Color(0xFFF59E0B); // Amber
  static const Color coral = Color(0xFFF43F5E); // Video Recording Rose/Coral

  // Surface colors for Dark Theme (Cyber / Obsidian aesthetics)
  static const Color darkCanvas = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardHover = Color(0xFF27354D);
  static const Color darkGlass = Color(0xCC0F172A);
  static const Color darkBorder = Color(0x26FFFFFF);

  // Surface colors for Light Theme (Clean Crisp Minimalist)
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightGlass = Color(0xEEFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Standard Border Radii
  static final BorderRadius radiusSmall = BorderRadius.circular(10);
  static final BorderRadius radiusMedium = BorderRadius.circular(16);
  static final BorderRadius radiusLarge = BorderRadius.circular(24);
  static final BorderRadius radiusFull = BorderRadius.circular(999);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  );

  static const LinearGradient videoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static LinearGradient glassCardGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xCC1E293B),
              const Color(0x990F172A),
            ]
          : [
              const Color(0xFAFFFFFF),
              const Color(0xEEF8FAFC),
            ],
    );
  }

  // Soft modern glow shadows
  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 20,
        spreadRadius: 1,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> softShadow(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : const Color(0x0D0F172A),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
