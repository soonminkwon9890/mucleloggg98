import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    @Default([]) List<ExerciseBaseline> baselines,
    @Default({}) Map<String, List<ExerciseBaseline>> groupedWorkouts,
    @Default(0.0) double totalVolume,
    @Default('기록 없음') String mainFocusArea,
    @Default(false) bool isLoading,
    String? errorMessage,
    // [NEW] 계획된 운동 추적용 (baseline_id -> PlannedWorkout 매핑)
    // 저장 시 is_converted_to_log 업데이트에 사용
    @Default({}) Map<String, PlannedWorkout> plannedWorkoutMap,
  }) = _HomeState;
}

