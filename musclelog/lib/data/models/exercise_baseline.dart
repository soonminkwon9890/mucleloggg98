import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_baseline.freezed.dart';
part 'exercise_baseline.g.dart';

/// 운동 기준 정보 모델
@freezed
class ExerciseBaseline with _$ExerciseBaseline {
  const factory ExerciseBaseline({
    required String id,
    required String userId,
    required String exerciseName, // 'BENCH_PRESS', 'SQUAT' 등
    String? targetMuscle, // 'CHEST', 'LEGS'
    String? bodyPart, // 'UPPER', 'LOWER', 'FULL'
    String? movementType, // 'PUSH', 'PULL'
    String? videoUrl, // 원본/압축 영상 경로
    String? thumbnailUrl, // 리스트 표시용 썸네일
    Map<String, dynamic>? skeletonData, // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
    String? feedbackPrompt, // "어깨 관절 개입 과다" 등 분석 내용
    DateTime? createdAt,
  }) = _ExerciseBaseline;

  factory ExerciseBaseline.fromJson(Map<String, dynamic> json) =>
      _$ExerciseBaselineFromJson(json);
}

