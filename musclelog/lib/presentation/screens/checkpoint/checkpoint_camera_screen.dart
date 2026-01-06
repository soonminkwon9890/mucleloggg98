import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/exercise_baseline.dart';

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
      body: const Center(
        child: Text('중간 점검 화면'),
      ),
    );
  }
}

