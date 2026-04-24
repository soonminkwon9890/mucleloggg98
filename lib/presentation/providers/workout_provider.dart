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

/// 홈 화면 날짜 선택 프로바이더 (오늘 기본값)
final selectedHomeDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 홈 화면 ViewModel 프로바이더
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return HomeViewModel(repository);
});

/// 운동 분석 대시보드 통계 (주간 볼륨 + 부위 밸런스)
/// - [weekStart] 주의 시작일(월요일). UI에서 주차가 변경될 때마다 새로운 데이터를 가져옴
final dashboardStatsProvider = FutureProvider.family.autoDispose<
    ({Map<DateTime, double> weeklyVolume, Map<String, double> bodyBalance}),
    DateTime>((ref, weekStart) async {
  final repository = ref.watch(workoutRepositoryProvider);

  final weeklyFuture = repository.getWeeklyVolume(weekStart: weekStart);
  final balanceFuture = repository.getBodyBalance(weekStart: weekStart);

  final weekly = await weeklyFuture;
  final balance = await balanceFuture;

  return (weeklyVolume: weekly, bodyBalance: balance);
});

/// 운동 분석 대시보드 월간 통계 (주차별 볼륨 + 부위 밸런스)
///
/// - [monthStart] 해당 월의 1일(정규화된 날짜). 월이 변경될 때마다 새로운 데이터를 가져옴.
/// - 반환: `weeklyGroupedVolume` (Map<int, double>: 1~5주차 키) + `bodyBalance`
final monthlyDashboardStatsProvider = FutureProvider.family.autoDispose<
    ({Map<int, double> weeklyGroupedVolume, Map<String, double> bodyBalance}),
    DateTime>((ref, monthStart) async {
  final repository = ref.watch(workoutRepositoryProvider);

  final volumeFuture =
      repository.getMonthlyVolumeByWeek(monthStart: monthStart);
  final balanceFuture =
      repository.getMonthlyBodyBalance(monthStart: monthStart);

  return (
    weeklyGroupedVolume: await volumeFuture,
    bodyBalance: await balanceFuture,
  );
});

/// 계획된 운동 데이터 갱신 트리거 (ProfileScreen 캘린더 동기화용)
final plannedWorkoutsRefreshProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// C.3: Provider Invalidation Helpers
// ============================================================================
//
// 여러 곳에서 반복되는 ref.invalidate() 호출을 중앙 집중화하여
// 일관성을 유지하고 누락을 방지합니다.
// ============================================================================

/// WidgetRef extension for centralized provider invalidation
extension WorkoutProviderInvalidation on WidgetRef {
  /// 운동 데이터 관련 프로바이더 무효화
  ///
  /// 사용 시점: 운동 추가, 삭제, 수정 후
  /// 영향: baselines, archivedBaselines, workoutDates
  void invalidateExerciseData() {
    invalidate(baselinesProvider);
    invalidate(archivedBaselinesProvider);
    invalidate(workoutDatesProvider);
  }

  /// 운동 삭제 시 프로바이더 무효화 (루틴 포함)
  ///
  /// 사용 시점: 운동 삭제 후 (루틴에 포함된 운동일 수 있음)
  /// 영향: baselines, archivedBaselines, workoutDates, routines
  void invalidateExerciseWithRoutines() {
    invalidate(baselinesProvider);
    invalidate(archivedBaselinesProvider);
    invalidate(workoutDatesProvider);
    invalidate(routinesProvider);
  }

  /// 루틴 데이터 관련 프로바이더 무효화
  ///
  /// 사용 시점: 루틴 생성, 수정, 삭제 후
  /// 영향: routines, baselines (루틴 그룹 변경 반영)
  void invalidateRoutineData() {
    invalidate(routinesProvider);
    invalidate(baselinesProvider);
  }

  /// 운동 기록 저장 후 프로바이더 무효화
  ///
  /// 사용 시점: 운동 완료 및 저장 후
  /// 영향: archivedBaselines, routines, workoutDates
  void invalidateAfterWorkoutSave() {
    invalidate(archivedBaselinesProvider);
    invalidate(routinesProvider);
    invalidate(workoutDatesProvider);
  }

  /// 전체 운동 데이터 프로바이더 무효화 (로그아웃/계정 전환 시)
  ///
  /// 사용 시점: 로그아웃, 계정 전환 후
  /// 영향: 모든 운동 관련 프로바이더
  void invalidateAllWorkoutData() {
    invalidate(homeViewModelProvider);
    invalidate(baselinesProvider);
    invalidate(archivedBaselinesProvider);
    invalidate(workoutDatesProvider);
    invalidate(routinesProvider);
    invalidate(exercisesWithHistoryProvider);
    invalidate(plannedWorkoutsRefreshProvider);
    invalidate(profileSearchTriggerProvider);
  }
}
