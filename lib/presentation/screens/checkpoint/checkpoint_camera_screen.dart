import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/exercise_baseline.dart';
import 'video_upload_screen.dart';

/// 중간 점검 화면
class CheckpointCameraScreen extends ConsumerWidget {
  final ExerciseBaseline baseline;

  const CheckpointCameraScreen({
    super.key,
    required this.baseline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${baseline.exerciseName} 중간 점검'),
      ),
      body: SafeArea(
        child: Center(
          child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoUploadScreen(
                  baseline: baseline,
                  isCheckpoint: true, // 중간 점검 모드
                ),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('영상 업로드 시작'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

