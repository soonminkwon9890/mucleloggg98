import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/exercise_enums.dart';
import '../../core/utils/json_converters.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

/// 운동 세트 기록 모델
@freezed
class WorkoutSet with _$WorkoutSet {
  const factory WorkoutSet({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'baseline_id') required String baselineId, // 어떤 운동의 로그인지 연결
    @JsonKey(
      name: 'weight',
      fromJson: JsonConverters.toDouble,
    )
    required double weight, // 무게 (kg)
    @JsonKey(
      name: 'reps',
      fromJson: JsonConverters.toInt,
    )
    required int reps, // 횟수
    @JsonKey(
      name: 'sets',
      fromJson: JsonConverters.toInt,
    )
    @Default(1)
    int sets, // 세트 수
    @JsonKey(
      name: 'rpe',
      fromJson: JsonConverters.toIntNullable,
    )
    int? rpe, // 1~10
    @JsonKey(
      name: 'rpe_level',
      fromJson: JsonConverters.rpeLevelFromCode,
      toJson: JsonConverters.rpeLevelToCode,
    )
    RpeLevel? rpeLevel, // Enum: low, medium, high
    @JsonKey(
      name: 'estimated_1rm',
      fromJson: JsonConverters.toDoubleNullable,
    )
    double? estimated1rm, // 계산된 1RM
    @JsonKey(name: 'is_ai_suggested')
    @Default(false)
    bool isAiSuggested, // AI 추천 값 수용 여부
    @JsonKey(
      name: 'performance_score',
      fromJson: JsonConverters.toDoubleNullable,
    )
    double? performanceScore, // 추가 성능 점수
    @JsonKey(name: 'is_completed')
    @Default(false)
    bool isCompleted, // 입력 중인 세트와 완료된 세트 구분
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}
