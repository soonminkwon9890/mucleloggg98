import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

/// 운동 세트 기록 모델
@freezed
class WorkoutSet with _$WorkoutSet {
  const factory WorkoutSet({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'baseline_id') required String baselineId, // 어떤 운동의 로그인지 연결
    @JsonKey(name: 'weight') required double weight, // 무게 (kg)
    @JsonKey(name: 'reps') required int reps, // 횟수
    @JsonKey(name: 'sets') @Default(1) int sets, // 세트 수
    @JsonKey(name: 'rpe') int? rpe, // 1~10
    @JsonKey(name: 'rpe_level') String? rpeLevel, // 'LOW', 'MEDIUM', 'HIGH' (하위 호환)
    @JsonKey(name: 'estimated_1rm') double? estimated1rm, // 계산된 1RM
    @JsonKey(name: 'is_ai_suggested') @Default(false) bool isAiSuggested, // AI 추천 값 수용 여부
    @JsonKey(name: 'performance_score') double? performanceScore, // 추가 성능 점수
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}

