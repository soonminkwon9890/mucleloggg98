import 'package:freezed_annotation/freezed_annotation.dart';
import 'workout_set.dart';
import '../../core/enums/exercise_enums.dart';
import '../../core/utils/json_converters.dart';

part 'exercise_baseline.freezed.dart';
part 'exercise_baseline.g.dart';

/// 운동 기준 정보 모델
@freezed
class ExerciseBaseline with _$ExerciseBaseline {
  const factory ExerciseBaseline({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'exercise_name') required String exerciseName, // 'BENCH_PRESS', 'SQUAT' 등
    @JsonKey(
      name: 'target_muscles',
      fromJson: _targetMusclesFromJson,
      toJson: _targetMusclesToJson,
    )
    List<String>? targetMuscles, // ['가슴', '등', '어깨'] 등
    @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode,
    )
    BodyPart? bodyPart, // Enum: upper, lower, full
    @JsonKey(name: 'video_url') String? videoUrl, // 원본/압축 영상 경로
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl, // 리스트 표시용 썸네일
    @JsonKey(name: 'skeleton_data') Map<String, dynamic>? skeletonData, // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
    @JsonKey(name: 'feedback_prompt') String? feedbackPrompt, // "어깨 관절 개입 과다" 등 분석 내용
    @JsonKey(name: 'workout_sets', includeToJson: false) List<WorkoutSet>? workoutSets, // 조인 쿼리 결과 매핑용 (읽기 전용)
    @JsonKey(name: 'routine_id') String? routineId, // 루틴 실행 이력 추적용
    @JsonKey(name: 'is_hidden_from_home') @Default(false) bool isHiddenFromHome, // 홈 화면에서 숨김 여부
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt, // 업데이트 시간
  }) = _ExerciseBaseline;

  factory ExerciseBaseline.fromJson(Map<String, dynamic> json) =>
      _$ExerciseBaselineFromJson(json);
}

/// targetMuscles JSON 변환 헬퍼 함수
List<String>? _targetMusclesFromJson(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

List<String>? _targetMusclesToJson(List<String>? value) {
  return value;
}

