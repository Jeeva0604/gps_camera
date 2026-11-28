import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available card watermark templates matching the design options:
/// 1. classic: Modern classic rounded map with location pill
/// 2. circular: Circular lens map with cobalt gradient accents
/// 3. polaroid: Polaroid tilted snapshot map with retro badge
/// 4. organic: Leaf/organic curve badge with emerald theme
/// 5. golden: Amber circle outline with warm autumn gradient
/// 6. hexagon: Hexagonal frame map with violet/indigo accents
enum CardTemplate {
  classic,
  circular,
  polaroid,
  organic,
  golden,
  hexagon;

  String get displayName {
    switch (this) {
      case CardTemplate.classic:
        return 'Classic Rounded';
      case CardTemplate.circular:
        return 'Circular Compass';
      case CardTemplate.polaroid:
        return 'Retro Polaroid';
      case CardTemplate.organic:
        return 'Organic Leaf';
      case CardTemplate.golden:
        return 'Amber Halo';
      case CardTemplate.hexagon:
        return 'Cyber Hexagon';
    }
  }

  String get description {
    switch (this) {
      case CardTemplate.classic:
        return 'Modern clean rounded satellite map with location pin';
      case CardTemplate.circular:
        return 'Futuristic circular lens viewport with cobalt accents';
      case CardTemplate.polaroid:
        return 'Classic tilted instant polaroid photo frame with spark';
      case CardTemplate.organic:
        return 'Smooth squircle frame adorned with vibrant green leaf';
      case CardTemplate.golden:
        return 'Warm golden border with amber location tag';
      case CardTemplate.hexagon:
        return 'Geometric 6-sided crystal frame with violet neon sparks';
    }
  }

  Color get accentColor {
    switch (this) {
      case CardTemplate.classic:
        return const Color(0xFF6366F1); // Indigo
      case CardTemplate.circular:
        return const Color(0xFF2563EB); // Royal Blue
      case CardTemplate.polaroid:
        return const Color(0xFFF43F5E); // Rose
      case CardTemplate.organic:
        return const Color(0xFF10B981); // Emerald
      case CardTemplate.golden:
        return const Color(0xFFF59E0B); // Amber
      case CardTemplate.hexagon:
        return const Color(0xFF8B5CF6); // Purple
    }
  }
}

class TemplateService extends ChangeNotifier {
  static final TemplateService instance = TemplateService._internal();
  TemplateService._internal();

  static const String _prefTemplateKey = 'selected_card_template';
  CardTemplate _currentTemplate = CardTemplate.classic;

  CardTemplate get currentTemplate => _currentTemplate;

  /// Loads the persisted template from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefTemplateKey);
      if (savedName != null) {
        _currentTemplate = CardTemplate.values.firstWhere(
          (t) => t.name == savedName,
          orElse: () => CardTemplate.classic,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Updates and persists the selected template across the app
  Future<void> setTemplate(CardTemplate template) async {
    if (_currentTemplate == template) return;
    _currentTemplate = template;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTemplateKey, template.name);
    } catch (_) {}
  }
}
