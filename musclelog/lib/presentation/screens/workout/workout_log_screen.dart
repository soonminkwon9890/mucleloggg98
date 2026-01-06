import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/exercise_baseline.dart';

/// 운동 기록 화면
class WorkoutLogScreen extends ConsumerWidget {
  final ExerciseBaseline baseline;

  const WorkoutLogScreen({
    super.key,
    required this.baseline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(baseline.exerciseName),
      ),
      body: const Center(
        child: Text('운동 기록 화면'),
      ),
    );
  }
}

