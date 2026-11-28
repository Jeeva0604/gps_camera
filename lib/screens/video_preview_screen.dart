import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../utils/app_design.dart';
import '../utils/toast_helper.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File videoFile;

  const VideoPreviewScreen({
    super.key,
    required this.videoFile,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveVideo() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await StorageService.saveToDownloads(
        widget.videoFile,
        isVideo: true,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        ToastHelper.show('Video saved to Downloads folder!');
        ReviewService.requestReviewAfterSave();
      } else {
        setState(() {
          _isSaving = false;
        });
        ToastHelper.show('Failed to save video to Downloads.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ToastHelper.show('Error saving video: $e');
      }
    }
  }

  Future<void> _shareVideo() async {
    await Share.shareXFiles(
      [XFile(widget.videoFile.path)],
      text: 'GPS Video recorded with GPS Map Camera',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Center Interactive Video Player
          Center(
            child: _isInitialized
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: AppDesign.accent),
          ),

          // 2. Top Header Bar
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: AppDesign.radiusFull,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: AppDesign.coral, size: 8),
                        SizedBox(width: 8),
                        Text(
                          'VIDEO PREVIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildGlassButton(
                    icon: HugeIcons.strokeRoundedShare01,
                    onTap: _shareVideo,
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Bottom Action Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Retake Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedRefresh,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Retake',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Save Video Hero Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  (_isSaving || _isSaved) ? null : _saveVideo,
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: _isSaved
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF059669),
                                            Color(0xFF10B981)
                                          ],
                                        )
                                      : AppDesign.primaryGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: AppDesign.glowShadow(
                                    _isSaved
                                        ? AppDesign.emerald
                                        : AppDesign.primary,
                                    opacity: 0.45,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSaving)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    else
                                      HugeIcon(
                                        icon: _isSaved
                                            ? HugeIcons
                                                .strokeRoundedCheckmarkCircle02
                                            : HugeIcons.strokeRoundedDownload01,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isSaving
                                          ? 'Saving...'
                                          : (_isSaved
                                              ? 'Saved Video'
                                              : 'Save to Downloads'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Center(
            child: HugeIcon(
              icon: icon,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}
