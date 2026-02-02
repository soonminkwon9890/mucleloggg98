import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/routine.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/enums/exercise_enums.dart';
import 'home_state.dart';

/// 홈 화면 ViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  final WorkoutRepository _repository;
  DateTime? _lastLoadedDate;

  HomeViewModel(this._repository) : super(const HomeState()) {
    _lastLoadedDate = DateTime.now();
  }

  /// 데이터 로드
  Future<void> loadBaselines() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final baselines = await _repository.getTodayBaselines();
      _lastLoadedDate = DateTime.now();

      final groupedWorkouts = _groupWorkouts(baselines);
      final allTodayWorkouts =
          groupedWorkouts.values.expand((list) => list).toList();
      final totalVolume = _calculateVolume(allTodayWorkouts);
      final mainFocusArea = _getFocusArea(allTodayWorkouts);

      state = state.copyWith(
        baselines: baselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: totalVolume,
        mainFocusArea: mainFocusArea,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await loadBaselines();
  }

  /// 운동 삭제 후 데이터 갱신
  /// 삭제 작업 후 반드시 호출하여 화면을 최신 상태로 업데이트
  Future<void> refreshAfterDeletion() async {
    // 약간의 텀을 줌 (DB 반영 시간 확보)
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 확실하게 새로고침
    await loadBaselines();
  }

  /// 운동 삭제 (Soft Delete)
  /// 홈 화면에서 운동을 숨김 처리하고 리스트를 새로고침합니다.
  Future<void> deleteWorkout(String baselineId) async {
    // 로딩 상태(isLoading)를 켜지 않습니다. (삭제는 즉각적인 느낌을 주기 위해)
    try {
      // 1. Repository 호출 (Soft Delete)
      await _repository.deleteTodayWorkoutsByBaseline(baselineId);

      // 2. [필수] DB 반영 시간 확보 (프레임 드랍 방지 및 동기화)
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. 리스트 새로고침 (최적화된 로직 사용)
      await loadBaselines();
      
    } catch (e) {
      // 에러 발생 시에만 상태 업데이트
      state = state.copyWith(errorMessage: '삭제 실패: $e');
    }
  }

  /// 날짜 변경 체크 및 자동 새로고침
  /// 앱 라이프사이클 이벤트용
  Future<void> checkDateAndRefresh() async {
    final today = DateTime.now();
    if (_lastLoadedDate == null) {
      await loadBaselines();
      return;
    }

    // 날짜가 변경되었는지 확인
    if (!DateFormatter.isSameDate(_lastLoadedDate!, today)) {
      await loadBaselines();
    }
  }

  /// 신규 운동 추가
  /// UI 요청을 Repository로 전달하고 화면을 갱신합니다.
  Future<void> addNewExercise(
    String name,
    String bodyPartCode,
    List<String> targetMuscles,
  ) async {
    // 로딩 상태 시작
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. DB 저장만 수행 (절대 여기서 loadBaselines() 호출 금지!)
      // 오늘 날짜 기준으로만 동작 (DateTime.now() 사용)
      await _repository.ensureExerciseVisible(
        name,
        bodyPartCode,
        targetMuscles,
      );

      // 2. 로딩 상태 끝 (성공) - 화면 갱신은 하지 않음
      //    loadBaselines() 삭제!! (패널이 닫힌 후 HomeScreen에서 호출됨)
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // 실패 시 에러 상태 업데이트 및 로딩 상태 해제
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow; // UI가 알 수 있도록 rethrow
    }
  }

  /// 루틴 저장
  Future<void> saveRoutine(String name, List<ExerciseBaseline> workouts) async {
    if (workouts.isEmpty) {
      state = state.copyWith(errorMessage: '저장할 운동이 없습니다.');
      return;
    }

    try {
      await _repository.saveRoutineFromWorkouts(name, workouts);
      await loadBaselines(); // 데이터 새로고침
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// 루틴 시작: 루틴의 운동들을 오늘 홈 화면에 추가
  ///
  /// Strict sequence:
  /// 1) ensureExerciseVisible (DB에 운동 존재/활성화 보장)
  /// 2) addTodayWorkout (오늘 운동으로 추가)
  /// 3) loadBaselines (홈 화면 상태 갱신)
  Future<void> startRoutine(Routine routine) async {
    state = state.copyWith(errorMessage: null);

    final items = routine.routineItems ?? const [];
    if (items.isEmpty) {
      state = state.copyWith(errorMessage: '루틴에 운동이 없습니다.');
      return;
    }

    try {
      for (final item in items) {
        final bodyPartCode = item.bodyPart?.code ?? BodyPart.full.code;

        // RoutineItem에는 targetMuscles가 없으므로 빈 리스트로 시작
        final baseline = await _repository.ensureExerciseVisible(
          item.exerciseName,
          bodyPartCode,
          const [],
        );

        await _repository.addTodayWorkout(
          baseline,
          routineId: routine.id,
        );
      }

      await loadBaselines();
    } catch (e) {
      state = state.copyWith(errorMessage: '루틴 시작 실패: $e');
      rethrow;
    }
  }

  /// 운동 그룹화 및 정렬
  Map<String, List<ExerciseBaseline>> _groupWorkouts(
      List<ExerciseBaseline> baselines) {
    // 중복 제거: 같은 baseline_id를 가진 운동은 한 번만 표시
    final seenIds = <String>{};
    final uniqueFiltered = baselines.where((baseline) {
      if (seenIds.contains(baseline.id)) {
        return false;
      }
      seenIds.add(baseline.id);
      return true;
    }).toList();

    // 정렬 로직
    // 1순위: 신규 운동 (routineId == null, createdAt 오름차순 = FIFO)
    // 2순위: 루틴 운동 (routineId != null, createdAt 오름차순)
    uniqueFiltered.sort((a, b) {
      // routineId가 null인 것을 먼저 (신규 운동)
      if (a.routineId == null && b.routineId != null) return -1;
      if (a.routineId != null && b.routineId == null) return 1;

      // 같은 그룹 내에서는 createdAt 오름차순 (오래된 것이 먼저 = FIFO)
      final aTime = a.createdAt ?? DateTime(1970);
      final bTime = b.createdAt ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });

    // routine_id 기준으로 그룹화 (정렬된 순서 유지)
    final Map<String, List<ExerciseBaseline>> grouped = {};
    for (final baseline in uniqueFiltered) {
      final key = baseline.routineId ?? "new";
      grouped.putIfAbsent(key, () => []).add(baseline);
    }

    return grouped;
  }

  /// 총 볼륨 계산
  double _calculateVolume(List<ExerciseBaseline> workouts) {
    double totalVolume = 0.0;
    final now = DateTime.now();

    for (final baseline in workouts) {
      if (baseline.workoutSets == null) continue;
      for (final set in baseline.workoutSets!) {
        if (DateFormatter.isSameDate(set.createdAt, now)) {
          totalVolume += set.weight * set.reps;
        }
      }
    }
    return totalVolume;
  }

  /// 입력값 메모리 업데이트 (DB 호출 X, 화면 갱신만 수행)
  /// 포커스가 해제될 때 호출되어 사용자 입력을 메모리에 반영합니다.
  void updateSetInMemory(String setId, {double? weight, int? reps}) {
    final updatedBaselines = state.baselines.map((baseline) {
      if (baseline.workoutSets == null) return baseline;

      final updatedSets = baseline.workoutSets!.map((set) {
        if (set.id == setId) {
          // 값이 변경된 경우에만 객체 복사
          return set.copyWith(
            weight: weight ?? set.weight,
            reps: reps ?? set.reps,
          );
        }
        return set;
      }).toList();

      return baseline.copyWith(workoutSets: updatedSets);
    }).toList();

    // 상태 업데이트 (화면에는 반영되지만 DB는 안 감)
    state = state.copyWith(baselines: updatedBaselines);
  }

  /// 주요 타겟 부위 계산
  String _getFocusArea(List<ExerciseBaseline> workouts) {
    // 오늘 수행한 운동들의 targetMuscles를 집계 (MovementType 제거)
    final muscles = workouts
        .map((w) => w.targetMuscles ?? const <String>[])
        .expand((list) => list)
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    if (muscles.isEmpty) {
      return '휴식';
    }

    // fold로 빈도수 계산
    final Map<String, int> counts = muscles.fold(<String, int>{}, (acc, m) {
      acc[m] = (acc[m] ?? 0) + 1;
      return acc;
    });

    // 정렬: 빈도 desc -> (동점) 가나다 asc
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final top = sorted.take(2).map((e) => e.key).toList();
    return top.join(', ');
  }
}
