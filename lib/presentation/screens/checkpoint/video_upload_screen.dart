import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/media_helper.dart';
import '../../../core/utils/video_compressor.dart';
import '../../../core/utils/adaptive_widgets.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../providers/workout_provider.dart';
import '../../screens/exercise/media_source_modal.dart';
import 'comparison_screen.dart';

/// 영상 업로드 화면 (중간 점검 및 후속 업로드용)
class VideoUploadScreen extends ConsumerStatefulWidget {
  final ExerciseBaseline baseline;
  final bool isCheckpoint; // 중간 점검인지 후속 업로드인지 구분

  const VideoUploadScreen({
    super.key,
    required this.baseline,
    this.isCheckpoint = false, // 기본값은 후속 업로드
  });

  @override
  ConsumerState<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends ConsumerState<VideoUploadScreen> {
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
          _isProcessing = true;
        });

        // 영상 처리
        final compressor = VideoCompressor();
        final compressedVideo = await compressor.compressVideo(videoFile);

        if (mounted) {
          if (compressedVideo != null && compressedVideo.path != null) {
            final repository = ref.read(workoutRepositoryProvider);
            final compressedVideoFile = File(compressedVideo.path!);

            // 영상 업로드
            final videoUrl = await repository.uploadVideo(
                compressedVideoFile, widget.baseline.id);
            final thumbnailFile =
                await compressor.generateThumbnail(compressedVideoFile);
            final thumbnailUrl = await repository.uploadThumbnail(
                thumbnailFile, widget.baseline.id);

            if (widget.isCheckpoint) {
              // 중간 점검인 경우 ComparisonScreen으로 이동
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComparisonScreen(
                      baseline: widget.baseline,
                      checkVideo: compressedVideoFile,
                    ),
                  ),
                );
              }
            } else {
              // 후속 업로드인 경우 Baseline 업데이트
              await repository.updateBaselineVideo(
                widget.baseline.id,
                videoUrl,
                thumbnailUrl,
              );

              // 화면 갱신
              ref.invalidate(baselinesProvider);

              if (mounted) {
                Navigator.pop(context, true); // 성공 결과 반환
              }
            }
          } else {
            // 압축 실패 시 원본 파일 사용
            final repository = ref.read(workoutRepositoryProvider);
            final videoUrl =
                await repository.uploadVideo(videoFile, widget.baseline.id);
            final thumbnailFile = await compressor.generateThumbnail(videoFile);
            final thumbnailUrl = await repository.uploadThumbnail(
                thumbnailFile, widget.baseline.id);

            if (!widget.isCheckpoint) {
              await repository.updateBaselineVideo(
                widget.baseline.id,
                videoUrl,
                thumbnailUrl,
              );
              ref.invalidate(baselinesProvider);
              if (mounted) {
                Navigator.pop(context, true);
              }
            }
          }

          setState(() => _isProcessing = false);
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
        title: Text(
          widget.isCheckpoint ? '중간 점검 영상 업로드' : '영상 등록',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isProcessing
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AdaptiveWidgets.buildAdaptiveLoadingIndicator(),
                    const SizedBox(height: 16),
                    const Text('영상을 처리하는 중...'),
                  ],
                )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    widget.isCheckpoint ? '중간 점검 영상을 업로드하세요' : '영상을 업로드하세요',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
