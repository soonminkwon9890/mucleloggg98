import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/models/exercise_with_history.dart';
import '../../data/models/workout_set.dart';
import '../../data/models/routine.dart';
import '../viewmodels/home_view_model.dart';
import '../viewmodels/home_state.dart';

/// 운동 레포지토리 프로바이더
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

/// 모든 운동 기준 정보 프로바이더
final baselinesProvider = FutureProvider<List<ExerciseBaseline>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getBaselines();
});

/// 보관함용 운동 목록 프로바이더 (autoDispose)
final archivedBaselinesProvider =
    FutureProvider.autoDispose<List<ExerciseBaseline>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getArchivedBaselines();
});

/// 특정 운동 기준 정보 프로바이더
final baselineProvider = FutureProvider.family<ExerciseBaseline?, String>(
  (ref, baselineId) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getBaselineById(baselineId);
  },
);

/// 특정 운동의 세트 기록 프로바이더
final workoutSetsProvider = FutureProvider.family<List<WorkoutSet>, String>(
  (ref, baselineId) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getWorkoutSets(baselineId);
  },
);

/// 최근 세트 기록 프로바이더
final latestWorkoutSetProvider = FutureProvider.family<WorkoutSet?, String>(
  (ref, baselineId) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getLatestWorkoutSet(baselineId);
  },
);

/// 운동 날짜 목록 프로바이더 (달력용)
final workoutDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getWorkoutDates();
});

/// 프로필 검색: 완료 기록 기반 운동+날짜 목록
final exercisesWithHistoryProvider =
    FutureProvider.autoDispose<List<ExerciseWithHistory>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getExercisesWithHistory();
});

/// 프로필 검색 시트 오픈 트리거 (MainScreen -> ProfileScreen)
final profileSearchTriggerProvider = StateProvider<int>((ref) => 0);

/// 모든 루틴 프로바이더
final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getRoutines();
});

/// 홈 화면 ViewModel 프로바이더
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return HomeViewModel(repository);
});

/// 오늘 날짜의 운동 기준 정보 프로바이더
final todayBaselinesProvider =
    FutureProvider<List<ExerciseBaseline>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getTodayBaselines();
});

/// 운동 분석 대시보드 통계 (주간 볼륨 + 부위 밸런스)
final dashboardStatsProvider = FutureProvider.autoDispose<
    ({Map<DateTime, double> weeklyVolume, Map<String, double> bodyBalance})>(
  (ref) async {
    final repository = ref.watch(workoutRepositoryProvider);

    final weeklyFuture = repository.getWeeklyVolume();
    final balanceFuture = repository.getBodyBalance();

    final weekly = await weeklyFuture;
    final balance = await balanceFuture;

    return (weeklyVolume: weekly, bodyBalance: balance);
  },
);
