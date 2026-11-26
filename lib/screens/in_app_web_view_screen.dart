import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse(widget.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
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
            tooltip: 'Refresh',
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: primaryTextColor,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _hasError = false;
              });
              _webViewController?.reload();
            },
          ),
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
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.url),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                transparentBackground: true,
                supportZoom: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                cacheEnabled: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                if (mounted) {
                  setState(() {
                    _progress = progress / 100;
                  });
                }
              },
              onReceivedError: (controller, request, error) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error.description;
                  });
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage =
                        'HTTP error: ${errorResponse.statusCode}';
                  });
                }
              },
            ),

            // Linear Progress Indicator on Top
            if (_progress < 1.0 && !_hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 2.5,
                ),
              ),

            // Error Overlay if page fails to load
            if (_hasError)
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.all(24.0),
                child: Center(
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
                        'Unable to load page',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : 'Please check your internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                              });
                              _webViewController?.reload();
                            },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedRefresh,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Try Again'),
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
                            label: const Text('Open in Browser'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.blueAccent),
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
              ),
          ],
        ),
      ),
    );
  }
}
