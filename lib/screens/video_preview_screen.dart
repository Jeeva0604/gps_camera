import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/gps_photo_data.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../utils/toast_helper.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File videoFile;
  final GpsPhotoData? gpsData;

  const VideoPreviewScreen({
    super.key,
    required this.videoFile,
    this.gpsData,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveToDownloads() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    final success = await StorageService.saveToDownloads(
      widget.videoFile,
      isVideo: true,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = success;
    });

    if (success) {
      ToastHelper.show('Video saved to Downloads folder!');
      ReviewService.requestReviewAfterSave();
    } else {
      ToastHelper.show('Failed to save video to Downloads.');
    }
  }

  Future<void> _shareVideo() async {
    final text = widget.gpsData != null
        ? 'GPS Video captured at ${widget.gpsData!.formattedCoordinates} - ${widget.gpsData!.fullAddress}'
        : 'GPS Video captured with GPS Camera';
    await Share.shareXFiles(
      [XFile(widget.videoFile.path)],
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Video Preview',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Share Video',
            onPressed: _shareVideo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // In-App Video Player Preview
            Expanded(
              child: Center(
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
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedPlay,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // Action Buttons Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedRefresh,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Retake',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isSaving || _isSaved) ? null : _saveToDownloads,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : HugeIcon(
                              icon: _isSaved
                                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                                  : HugeIcons.strokeRoundedDownload01,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: Text(_isSaving
                          ? 'Saving...'
                          : (_isSaved ? 'Saved' : 'Save Video')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved ? const Color(0xFF10B981) : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
}
