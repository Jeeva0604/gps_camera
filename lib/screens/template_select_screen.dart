import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/template_service.dart';
import '../services/theme_service.dart';
import '../utils/app_design.dart';

class TemplateSelectScreen extends StatelessWidget {
  const TemplateSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService.instance, TemplateService.instance]),
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;
        final selectedTemplate = TemplateService.instance.currentTemplate;

        final backgroundColor =
            isDark ? AppDesign.darkCanvas : AppDesign.lightCanvas;
        final primaryTextColor =
            isDark ? AppDesign.darkTextPrimary : AppDesign.lightTextPrimary;
        final secondaryTextColor =
            isDark ? AppDesign.darkTextSecondary : AppDesign.lightTextSecondary;

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
              'Select Watermark Template',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: CardTemplate.values.length,
            itemBuilder: (context, index) {
              final template = CardTemplate.values[index];
              final isSelected = template == selectedTemplate;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    TemplateService.instance.setTemplate(template);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppDesign.darkCard : AppDesign.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? template.accentColor
                            : (isDark
                                ? AppDesign.darkBorder
                                : AppDesign.lightBorder),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? AppDesign.glowShadow(template.accentColor,
                              opacity: 0.3)
                          : AppDesign.softShadow(isDark),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template Header info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: template.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: HugeIcon(
                                icon: _getTemplateIcon(template),
                                color: template.accentColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.displayName,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    template.description,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: template.accentColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle02,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Mini visual live preview of card template
                        _buildTemplateVisualPreview(template, isDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static dynamic _getTemplateIcon(CardTemplate template) {
    switch (template) {
      case CardTemplate.classic:
        return HugeIcons.strokeRoundedLocation01;
      case CardTemplate.circular:
        return HugeIcons.strokeRoundedCompass01;
      case CardTemplate.polaroid:
        return HugeIcons.strokeRoundedImage01;
      case CardTemplate.organic:
        return HugeIcons.strokeRoundedEcoEnergy;
      case CardTemplate.golden:
        return HugeIcons.strokeRoundedSun01;
      case CardTemplate.hexagon:
        return HugeIcons.strokeRoundedDiamond;
    }
  }

  Widget _buildTemplateVisualPreview(CardTemplate template, bool isDark) {
    final bgColor = isDark ? const Color(0xE81A202C) : const Color(0xF5FFFFFF);
    final borderColor = template.accentColor.withValues(alpha: 0.3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Map Shape representation
          _buildMapShape(template),

          const SizedBox(width: 12),

          // Text content representation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Andipatti, Tamil Nadu',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: template.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '10.2 km',
                        style: TextStyle(
                          color: template.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('🇮🇳 India', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  '2j36+r3, Andipatti, Theni',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lat 10.004553° Long 77.610243°',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapShape(CardTemplate template) {
    const size = 56.0;
    const placeholderImg = 'assets/icon/app_icon.png';

    switch (template) {
      case CardTemplate.classic:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            color: const Color(0xFF334155),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
              ],
            ),
          ),
        );

      case CardTemplate.circular:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
              ],
            ),
          ),
        );

      case CardTemplate.polaroid:
        return Transform.rotate(
          angle: -0.06,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              ],
            ),
          ),
        );

      case CardTemplate.organic:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              left: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 12),
              ),
            ),
          ],
        );

      case CardTemplate.golden:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
              ],
            ),
          ),
        );

      case CardTemplate.hexagon:
        return ClipPath(
          clipper: _HexagonClipper(),
          child: Container(
            width: size,
            height: size,
            color: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.all(2),
            child: ClipPath(
              clipper: _HexagonClipper(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(placeholderImg, fit: BoxFit.cover, width: size, height: size),
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
