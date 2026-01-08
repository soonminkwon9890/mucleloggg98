import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/exercise_baseline.dart';

/// 비교 분석 화면 (중간 점검용)
class ComparisonScreen extends StatelessWidget {
  final ExerciseBaseline baseline;
  final File checkVideo;

  const ComparisonScreen({
    super.key,
    required this.baseline,
    required this.checkVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${baseline.exerciseName} 비교 분석'),
      ),
      body: const Center(
        child: Text('비교 분석 준비 중'),
      ),
    );
  }
}

