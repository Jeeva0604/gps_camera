import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/theme_service.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const InAppWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  bool _isLoading = true;
  String? _htmlContent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWebPage();
  }

  Future<void> _fetchWebPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _htmlContent = _cleanHtmlContent(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load content (HTTP ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to connect. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  String _cleanHtmlContent(String rawHtml) {
    // Basic text extractor removing HTML tags & scripts while preserving paragraphs
    String text = rawHtml;

    // Remove script and style tags and contents
    text = text.replaceAll(RegExp(r'<script[\s\S]*?</script>'), '');
    text = text.replaceAll(RegExp(r'<style[\s\S]*?</style>'), '');
    text = text.replaceAll(RegExp(r'<head[\s\S]*?</head>'), '');

    // Replace break and paragraph tags with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(
        RegExp(r'</h1>|</h2>|</h3>|</h4>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    // Remove remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode standard HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–');

    // Collapse multiple blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse(widget.url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
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
          widget.title,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in Browser',
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              color: primaryTextColor,
              size: 20,
            ),
            onPressed: _openExternalBrowser,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${widget.title}...',
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _fetchWebPage,
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedRefresh,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _openExternalBrowser,
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedShare01,
                                  size: 18,
                                  color: Colors.blueAccent,
                                ),
                                label: const Text('Open Browser'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                  side: const BorderSide(
                                      color: Colors.blueAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _htmlContent ?? '',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14.5,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
