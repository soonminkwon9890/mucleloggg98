import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/json_converters.dart';

part 'planned_workout.freezed.dart';
part 'planned_workout.g.dart';

@freezed
class PlannedWorkout with _$PlannedWorkout {
  const factory PlannedWorkout({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'baseline_id') required String baselineId,
    @JsonKey(name: 'scheduled_date') required DateTime scheduledDate,
    @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble) required double targetWeight,
    @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt) required int targetReps,
    @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt) @Default(3) int targetSets,
    @JsonKey(name: 'ai_comment') String? aiComment,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'exercise_name') String? exerciseName, // 운동 이름 (디노멀라이제이션)
    @JsonKey(name: 'is_converted_to_log') @Default(false) bool isConvertedToLog, // 이미 WorkoutSet으로 변환되었는지 여부
    @JsonKey(name: 'color_hex') @Default('0xFF2196F3') String colorHex, // 캘린더 색상
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PlannedWorkout;

  factory PlannedWorkout.fromJson(Map<String, dynamic> json) =>
      _$PlannedWorkoutFromJson(json);
}

