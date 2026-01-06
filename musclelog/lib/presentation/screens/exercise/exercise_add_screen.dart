import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/media_helper.dart';
import '../../../core/utils/video_compressor.dart';
import 'media_source_modal.dart';
import 'exercise_input_screen.dart';

/// 운동 추가 화면
class ExerciseAddScreen extends ConsumerStatefulWidget {
  const ExerciseAddScreen({super.key});

  @override
  ConsumerState<ExerciseAddScreen> createState() => _ExerciseAddScreenState();
}

class _ExerciseAddScreenState extends ConsumerState<ExerciseAddScreen> {
  File? _selectedVideo;
  File? _thumbnailFile;
  bool _isProcessing = false;

  Future<void> _selectVideoSource(String source) async {
    try {
      File? videoFile;
      
      if (source == 'camera') {
        videoFile = await MediaHelper.pickVideoFromCamera();
      } else if (source == 'gallery') {
        videoFile = await MediaHelper.pickVideoFromGallery();
      }

      if (videoFile != null) {
        setState(() {
          _selectedVideo = videoFile;
          _isProcessing = true;
        });

        // 영상 압축 및 썸네일 생성
        final compressor = VideoCompressor();
        final compressedVideo = await compressor.compressVideo(videoFile);
        final thumbnail = await compressor.generateThumbnail(videoFile);

        if (mounted) {
        setState(() {
          _isProcessing = false;
          _thumbnailFile = thumbnail;
          final compressedPath = compressedVideo?.path;
          if (compressedPath != null) {
            _selectedVideo = File(compressedPath);
          }
        });

          // 운동 입력 화면으로 이동
          if (_selectedVideo != null && _thumbnailFile != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseInputScreen(
                  videoFile: _selectedVideo!,
                  thumbnailFile: _thumbnailFile!,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  void _showSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MediaSourceModal(
        onSourceSelected: _selectVideoSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 추가'),
      ),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('영상을 처리하는 중...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '운동 영상을 추가하세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '카메라로 촬영하거나 갤러리에서 선택할 수 있습니다',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showSourceModal,
                    icon: const Icon(Icons.video_library),
                    label: const Text('영상 선택'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

