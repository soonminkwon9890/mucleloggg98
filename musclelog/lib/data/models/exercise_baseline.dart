import 'package:freezed_annotation/freezed_annotation.dart';
import 'workout_set.dart';

part 'exercise_baseline.freezed.dart';
part 'exercise_baseline.g.dart';

/// 운동 기준 정보 모델
@freezed
class ExerciseBaseline with _$ExerciseBaseline {
  const factory ExerciseBaseline({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'exercise_name') required String exerciseName, // 'BENCH_PRESS', 'SQUAT' 등
    @JsonKey(name: 'target_muscle') String? targetMuscle, // 'CHEST', 'LEGS'
    @JsonKey(name: 'body_part') String? bodyPart, // 'UPPER', 'LOWER', 'FULL'
    @JsonKey(name: 'movement_type') String? movementType, // 'PUSH', 'PULL'
    @JsonKey(name: 'video_url') String? videoUrl, // 원본/압축 영상 경로
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl, // 리스트 표시용 썸네일
    @JsonKey(name: 'skeleton_data') Map<String, dynamic>? skeletonData, // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
    @JsonKey(name: 'feedback_prompt') String? feedbackPrompt, // "어깨 관절 개입 과다" 등 분석 내용
    @JsonKey(name: 'workout_sets', includeToJson: false) List<WorkoutSet>? workoutSets, // 조인 쿼리 결과 매핑용 (읽기 전용)
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ExerciseBaseline;

  factory ExerciseBaseline.fromJson(Map<String, dynamic> json) =>
      _$ExerciseBaselineFromJson(json);
}

