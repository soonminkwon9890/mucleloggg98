import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

/// 운동 세트 기록 모델
@freezed
class WorkoutSet with _$WorkoutSet {
  const factory WorkoutSet({
    required String id,
    required String baselineId, // 어떤 운동의 로그인지 연결
    required double weight, // 무게 (kg)
    required int reps, // 횟수
    int? rpe, // 1~10
    String? rpeLevel, // 'LOW', 'MEDIUM', 'HIGH' (하위 호환)
    double? estimated1rm, // 계산된 1RM
    @Default(false) bool isAiSuggested, // AI 추천 값 수용 여부
    double? performanceScore, // 추가 성능 점수
    DateTime? createdAt,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}

