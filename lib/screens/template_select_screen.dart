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
      listenable:
          Listenable.merge([ThemeService.instance, TemplateService.instance]),
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
                                color: template.accentColor
                                    .withValues(alpha: 0.15),
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
    final bgColor = template == CardTemplate.classic
        ? (isDark ? const Color(0xE81A202C) : const Color(0xF5FFFFFF))
        : template.cardBackgroundColor;
    final borderColor = template == CardTemplate.classic
        ? (isDark ? Colors.white24 : Colors.black12)
        : template.cardBorderColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Wave background for non-classic templates
            if (template != CardTemplate.classic)
              Positioned(
                right: -20,
                bottom: -25,
                child: CustomPaint(
                  size: const Size(140, 90),
                  painter: _PreviewWavePainter(waveColors: template.waveColors),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Shape representation
                  _buildMapShape(template),

                  const SizedBox(width: 10),

                  // Text content representation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          template.wonderTitle,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(template.wonderFlag,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(template.wonderCountry,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          template.wonderAddress,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedNavigation01,
                              color: Colors.white70,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                template.wonderCoordinates,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                Image.asset(placeholderImg,
                    fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on,
                    color: Colors.redAccent, size: 22),
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
                Image.asset(placeholderImg,
                    fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on,
                    color: Colors.redAccent, size: 22),
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
                Image.asset(placeholderImg,
                    fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on,
                    color: Colors.redAccent, size: 20),
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
                  border:
                      Border.all(color: const Color(0xFF10B981), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(placeholderImg,
                        fit: BoxFit.cover, width: size, height: size),
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 20),
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
                Image.asset(placeholderImg,
                    fit: BoxFit.cover, width: size, height: size),
                const Icon(Icons.location_on,
                    color: Colors.redAccent, size: 22),
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
                  Image.asset(placeholderImg,
                      fit: BoxFit.cover, width: size, height: size),
                  const Icon(Icons.location_on,
                      color: Colors.redAccent, size: 20),
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

class _PreviewWavePainter extends CustomPainter {
  final List<Color> waveColors;

  _PreviewWavePainter({required this.waveColors});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveColors.isEmpty) return;

    final w = size.width;
    final h = size.height;

    final path1 = Path();
    path1.moveTo(0, h * 0.7);
    path1.quadraticBezierTo(w * 0.4, h * 0.2, w, h * 0.5);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, Paint()..color = waveColors[0]);

    if (waveColors.length > 1) {
      final path2 = Path();
      path2.moveTo(w * 0.2, h);
      path2.quadraticBezierTo(w * 0.6, h * 0.45, w, h * 0.75);
      path2.lineTo(w, h);
      path2.close();
      canvas.drawPath(path2, Paint()..color = waveColors[1]);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewWavePainter oldDelegate) =>
      oldDelegate.waveColors != waveColors;
}
