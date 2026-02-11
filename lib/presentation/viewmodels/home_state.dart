import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../data/models/exercise_baseline.dart';

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
  }) = _HomeState;
}

