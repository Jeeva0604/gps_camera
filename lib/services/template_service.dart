import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available card watermark templates matching the reference design:
/// 1. classic: Modern classic rounded map with clean layout
/// 2. circular: Circular lens map with cobalt gradient accents & waves
/// 3. polaroid: Polaroid tilted snapshot map with maroon/burgundy gradient waves & pink pin
/// 4. organic: Squircle frame with leaf emblem & deep emerald forest gradient waves
/// 5. golden: Amber halo circle with dark chocolate / golden caramel waves
/// 6. hexagon: Hexagonal frame with neon sparks & deep royal purple/violet gradient waves
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
        return 'Futuristic circular lens viewport with cobalt blue wave theme';
      case CardTemplate.polaroid:
        return 'Classic tilted polaroid frame with deep maroon/wine wave theme';
      case CardTemplate.organic:
        return 'Squircle frame with vibrant green leaf & forest emerald wave theme';
      case CardTemplate.golden:
        return 'Warm golden circle with rich dark amber & bronze wave theme';
      case CardTemplate.hexagon:
        return 'Geometric 6-sided crystal frame with purple & violet neon wave theme';
    }
  }

  /// Primary vibrant accent color for badge / borders
  Color get accentColor {
    switch (this) {
      case CardTemplate.classic:
        return const Color(0xFF6366F1); // Indigo
      case CardTemplate.circular:
        return const Color(0xFF1D6EEA); // Electric Royal Blue
      case CardTemplate.polaroid:
        return const Color(0xFFE11D48); // Rose / Crimson
      case CardTemplate.organic:
        return const Color(0xFF10B981); // Emerald Green
      case CardTemplate.golden:
        return const Color(0xFFF59E0B); // Amber / Gold
      case CardTemplate.hexagon:
        return const Color(0xFF8B5CF6); // Bright Violet
    }
  }

  /// 7 Wonders sample display data for Template Selection Page
  String get wonderTitle {
    switch (this) {
      case CardTemplate.classic:
        return 'Taj Mahal, Agra';
      case CardTemplate.circular:
        return 'Great Wall of China, Beijing';
      case CardTemplate.polaroid:
        return 'Petra, Ma\'an Governorate';
      case CardTemplate.organic:
        return 'Machu Picchu, Cusco Region';
      case CardTemplate.golden:
        return 'Colosseum, Rome';
      case CardTemplate.hexagon:
        return 'Christ the Redeemer, Rio de Janeiro';
    }
  }

  String get wonderCountry {
    switch (this) {
      case CardTemplate.classic:
        return 'India';
      case CardTemplate.circular:
        return 'China';
      case CardTemplate.polaroid:
        return 'Jordan';
      case CardTemplate.organic:
        return 'Peru';
      case CardTemplate.golden:
        return 'Italy';
      case CardTemplate.hexagon:
        return 'Brazil';
    }
  }

  String get wonderFlag {
    switch (this) {
      case CardTemplate.classic:
        return '🇮🇳';
      case CardTemplate.circular:
        return '🇨🇳';
      case CardTemplate.polaroid:
        return '🇯🇴';
      case CardTemplate.organic:
        return '🇵🇪';
      case CardTemplate.golden:
        return '🇮🇹';
      case CardTemplate.hexagon:
        return '🇧🇷';
    }
  }

  String get wonderAddress {
    switch (this) {
      case CardTemplate.classic:
        return 'Dharmapuri, Forest Colony, Tajganj, Agra, Uttar Pradesh 282001';
      case CardTemplate.circular:
        return 'Huairou District, Beijing 101405';
      case CardTemplate.polaroid:
        return 'Wadi Musa, Ma\'an Governorate 71810';
      case CardTemplate.organic:
        return '08680 Urubamba Province, Cusco Region';
      case CardTemplate.golden:
        return 'Piazza del Colosseo, 1, 00184 Roma RM';
      case CardTemplate.hexagon:
        return 'Parque Nacional da Tijuca, Alto da Boa Vista, Rio de Janeiro - RJ';
    }
  }

  String get wonderCoordinates {
    switch (this) {
      case CardTemplate.classic:
        return 'Lat 27.175144° Long 78.042142°';
      case CardTemplate.circular:
        return 'Lat 40.431908° Long 116.570374°';
      case CardTemplate.polaroid:
        return 'Lat 30.328454° Long 35.444362°';
      case CardTemplate.organic:
        return 'Lat -13.163141° Long -72.544963°';
      case CardTemplate.golden:
        return 'Lat 41.890210° Long 12.492231°';
      case CardTemplate.hexagon:
        return 'Lat -22.951916° Long -43.210487°';
    }
  }

  /// Card base background color
  Color get cardBackgroundColor {
    switch (this) {
      case CardTemplate.classic:
        return const Color(0xFF1E232B);
      case CardTemplate.circular:
        return const Color(0xFF0F1A2E); // Deep cobalt navy
      case CardTemplate.polaroid:
        return const Color(0xFF24101A); // Deep wine / dark maroon
      case CardTemplate.organic:
        return const Color(0xFF0D1E18); // Deep forest green
      case CardTemplate.golden:
        return const Color(0xFF24180E); // Deep espresso / dark bronze
      case CardTemplate.hexagon:
        return const Color(0xFF181128); // Deep dark purple / obsidian violet
    }
  }

  /// Card outer border color
  Color get cardBorderColor {
    switch (this) {
      case CardTemplate.classic:
        return const Color(0x60FFFFFF);
      case CardTemplate.circular:
        return const Color(0xFF1E40AF); // Blue border
      case CardTemplate.polaroid:
        return const Color(0xFF831843); // Dark rose border
      case CardTemplate.organic:
        return const Color(0xFF065F46); // Forest border
      case CardTemplate.golden:
        return const Color(0xFF92400E); // Bronze border
      case CardTemplate.hexagon:
        return const Color(0xFF5B21B6); // Deep violet border
    }
  }

  /// Flowing decorative wave shape colors at bottom-right
  List<Color> get waveColors {
    switch (this) {
      case CardTemplate.classic:
        return [const Color(0x1A6366F1), const Color(0x00000000)];
      case CardTemplate.circular:
        return [const Color(0x551E40AF), const Color(0x331D4ED8)]; // Cobalt blue waves
      case CardTemplate.polaroid:
        return [const Color(0x55881337), const Color(0x33BE123C)]; // Deep wine/ruby waves
      case CardTemplate.organic:
        return [const Color(0x55065F46), const Color(0x33047857)]; // Dark emerald waves
      case CardTemplate.golden:
        return [const Color(0x5578350F), const Color(0x33B45309)]; // Amber bronze waves
      case CardTemplate.hexagon:
        return [const Color(0x554C1D95), const Color(0x336D28D9)]; // Deep violet waves
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
