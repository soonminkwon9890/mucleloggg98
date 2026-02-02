import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/json_converters.dart';

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

@freezed
class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'baseline_id') required String baselineId,
    @JsonKey(name: 'workout_date') required DateTime workoutDate,
    @JsonKey(name: 'difficulty') required String difficulty, // 'easy', 'normal', 'hard'
    @JsonKey(name: 'total_volume', fromJson: JsonConverters.toDoubleNullable) double? totalVolume,
    @JsonKey(name: 'duration_minutes', fromJson: JsonConverters.toIntNullable) int? durationMinutes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
}

