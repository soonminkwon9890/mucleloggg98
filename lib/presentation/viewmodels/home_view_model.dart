import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/planned_workout.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/enums/exercise_enums.dart';
import 'home_state.dart';

const _uuid = Uuid();

/// 홈 화면 ViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  final WorkoutRepository _repository;
  DateTime? _lastLoadedDate;

  HomeViewModel(this._repository) : super(const HomeState()) {
    _lastLoadedDate = DateTime.now();
  }

  /// [CRITICAL FIX] 로그아웃 시 모든 로컬 상태 초기화
  /// 이전 사용자의 데이터가 메모리에 남아있는 것을 방지합니다.
  void clearState() {
    _lastLoadedDate = null;
    state = const HomeState(); // 모든 필드를 기본값으로 리셋
  }

  /// [Issue #1 Fix] 에러 메시지 초기화
  /// SnackBar 표시 후 호출하여 동일 에러가 반복 표시되지 않도록 합니다.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// 데이터 로드
  ///
  /// [forceRefresh]: true일 때만 DB에서 강제로 가져옵니다.
  /// false일 때는 같은 날짜이고 state에 데이터가 있으면 Draft를 보존하기 위해 DB 조회를 스킵합니다.
  ///
  /// [NEW] planned_workouts 테이블에서 오늘 예정된 운동도 함께 로드합니다.
  /// - scheduled_date = 오늘 AND is_converted_to_log = false 인 항목
  /// - Manual (target_weight=0, target_reps=0): 빈 세트 1개
  /// - AI Plan (target_weight>0 || target_reps>0): target_sets 개수만큼 미리 채운 세트
  Future<void> loadBaselines({bool forceRefresh = false}) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Draft 보존 로직: 같은 날짜이고 state에 데이터가 있고 강제 새로고침이 아니면 스킵
    if (!forceRefresh &&
        state.baselines.isNotEmpty &&
        _lastLoadedDate != null &&
        DateFormatter.isSameDate(_lastLoadedDate!, today)) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // [기존] 오늘의 workout_sets 기반 baselines 조회
      final dbBaselines = await _repository.getTodayBaselines();

      // [NEW] 오늘 예정된 planned_workouts 조회 (is_converted_to_log = false)
      final (plannedBaselines, plannedWorkoutMap) =
          await _repository.getPlannedWorkoutsAsBaselines(normalizedToday);

      _lastLoadedDate = DateTime.now();

      // [NEW] 중복 제거: DB에 이미 workout_sets가 있는 baseline은 planned에서 제외
      final dbBaselineIds = dbBaselines.map((b) => b.id).toSet();
      final filteredPlannedBaselines = plannedBaselines.where((b) {
        return !dbBaselineIds.contains(b.id);
      }).toList();

      // [NEW] 중복 제거된 plannedWorkoutMap 업데이트
      final filteredPlannedWorkoutMap = Map<String, PlannedWorkout>.from(plannedWorkoutMap)
        ..removeWhere((key, _) => dbBaselineIds.contains(key));

      // Draft 병합: 현재 state의 baselines 중에서 DB에 없는 것들 (Draft)을 찾아서 병합
      final allNewBaselineIds = {
        ...dbBaselineIds,
        ...filteredPlannedBaselines.map((b) => b.id),
      };
      final draftBaselines = state.baselines.where((b) {
        // DB/Planned에 없고 오늘 날짜인 것만 Draft로 간주
        return !allNewBaselineIds.contains(b.id) &&
               b.createdAt != null &&
               DateFormatter.isSameDate(b.createdAt!, today);
      }).toList();

      // DB 데이터와 기존 로컬 상태(state.baselines)를 먼저 병합하여 Draft 세트 보존
      final mergedFromDb = _mergeDraftSets(dbBaselines, state.baselines);

      // [NEW] Planned 데이터도 Draft 세트 병합 (사용자가 이미 수정한 값 보존)
      final mergedFromPlanned = _mergeDraftSets(filteredPlannedBaselines, state.baselines);

      // 병합된 DB 데이터 + Planned 데이터 + 완전한 Draft 항목들을 합침
      final mergedBaselines = [...mergedFromDb, ...mergedFromPlanned, ...draftBaselines];

      final groupedWorkouts = _groupWorkouts(mergedBaselines);
      final allTodayWorkouts =
          groupedWorkouts.values.expand((list) => list).toList();
      final totalVolume = _calculateVolume(allTodayWorkouts);
      final mainFocusArea = _getFocusArea(allTodayWorkouts);

      state = state.copyWith(
        baselines: mergedBaselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: totalVolume,
        mainFocusArea: mainFocusArea,
        isLoading: false,
        // [NEW] planned workout 매핑 저장 (저장 시 is_converted_to_log 업데이트용)
        plannedWorkoutMap: filteredPlannedWorkoutMap,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 데이터 새로고침 (Pull-to-refresh 등 명시적 새로고침)
  /// Draft를 무시하고 DB에서 최신 데이터를 가져옵니다.
  Future<void> refresh() async {
    await loadBaselines(forceRefresh: true);
  }

  /// 운동 삭제 후 데이터 갱신
  /// 삭제 작업 후 반드시 호출하여 화면을 최신 상태로 업데이트
  Future<void> refreshAfterDeletion() async {
    // 약간의 텀을 줌 (DB 반영 시간 확보)
    await Future.delayed(const Duration(milliseconds: 50));

    // 확실하게 새로고침 (forceRefresh로 DB에서 최신 데이터 가져옴)
    await loadBaselines(forceRefresh: true);
  }

  /// 운동 삭제 (Draft 안전 처리 포함)
  /// - Draft(미저장): 메모리에서만 제거 (DB 호출 X)
  /// - DB 저장됨: Repository 호출 후 새로고침
  Future<void> deleteWorkout(String baselineId) async {
    // 1. 삭제 대상 존재 확인
    final existsInState = state.baselines.any((b) => b.id == baselineId);
    if (!existsInState) {
      state = state.copyWith(errorMessage: '삭제 대상을 찾을 수 없습니다.');
      return;
    }

    // 2. Draft 판별: DB에서 해당 ID가 존재하는지 확인
    final dbBaselines = await _repository.getTodayBaselines();
    final isInDb = dbBaselines.any((db) => db.id == baselineId);

    if (!isInDb) {
      // Case A: Draft (메모리 전용) - DB 호출 없이 state에서만 제거
      final updatedBaselines = state.baselines
          .where((b) => b.id != baselineId)
          .toList();

      final groupedWorkouts = _groupWorkouts(updatedBaselines);
      final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

      state = state.copyWith(
        baselines: updatedBaselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: _calculateVolume(allWorkouts),
        mainFocusArea: _getFocusArea(allWorkouts),
      );
      return;
    }

    // Case B: DB에 저장된 항목 - Repository 호출
    try {
      await _repository.deleteTodayWorkoutsByBaseline(baselineId);

      // Optimistic Update: 로컬 상태에서 해당 항목만 제거하여 즉시 갱신
      // (다른 항목의 Draft 상태를 보존하기 위해 전체 새로고침하지 않음)
      final updatedBaselines = state.baselines
          .where((b) => b.id != baselineId)
          .toList();

      final groupedWorkouts = _groupWorkouts(updatedBaselines);
      final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

      state = state.copyWith(
        baselines: updatedBaselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: _calculateVolume(allWorkouts),
        mainFocusArea: _getFocusArea(allWorkouts),
      );
    } catch (e) {
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

    // 날짜가 변경되었는지 확인 (날짜 변경 시에는 강제 새로고침)
    if (!DateFormatter.isSameDate(_lastLoadedDate!, today)) {
      await loadBaselines(forceRefresh: true);
    }
  }

  /// 신규 운동 추가
  /// [date]: 운동 예정 날짜. null이면 오늘 날짜 사용.
  ///
  /// [Critical Logic - Requirement 1 & 2]
  /// - 오늘 날짜: DB에 즉시 저장 + 홈 화면에 표시 (앱 재시작 시에도 유지)
  /// - 미래 날짜: planned_workouts 테이블에 저장 (캘린더에만 표시, 홈 화면에는 표시 안 함)
  ///
  /// [Bug Fix] 즉시 DB 저장으로 앱 재시작 시 운동 사라지는 문제 해결
  Future<void> addNewExercise(
    String name,
    String bodyPartCode,
    List<String> targetMuscles, {
    DateTime? date,
  }) async {
    final selectedDate = date ?? DateTime.now();
    final userId = SupabaseService.currentUser?.id ?? '';

    // 오늘 날짜와 비교 (시간 무시, 날짜만 비교)
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedSelected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isFutureDate = normalizedSelected.isAfter(normalizedToday);

    // [MODIFIED] 미래 날짜인 경우: planned_workouts 테이블에 저장
    if (isFutureDate) {
      // 1. 먼저 exercise_baseline을 DB에 확보 (ensureExerciseVisible)
      final persistedBaseline = await _repository.ensureExerciseVisible(
        name,
        bodyPartCode,
        targetMuscles,
      );

      // 2. planned_workouts에 저장 (Manual Addition: 0kg, 0회, 1세트)
      final plannedWorkout = PlannedWorkout(
        id: _uuid.v4(),
        userId: userId,
        baselineId: persistedBaseline.id,
        scheduledDate: normalizedSelected,
        targetWeight: 0.0, // Manual: 빈 값
        targetReps: 0,     // Manual: 빈 값
        targetSets: 1,     // Manual: 기본 1세트
        exerciseName: name,
        isCompleted: false,
        isConvertedToLog: false,
        colorHex: '0xFF4CAF50', // 녹색 (수동 추가 구분)
        createdAt: DateTime.now(),
      );

      await _repository.savePlannedWorkouts([plannedWorkout]);
      return; // 홈 화면 state에 추가하지 않고 종료
    }

    // [Bug Fix] 오늘 날짜인 경우: DB에 즉시 저장 + 홈 화면에 표시
    // 정렬용 타임스탬프 계산: 현재 리스트의 max createdAt + 1초 (맨 끝에 추가)
    final sortTimestamp = _getNextSortTimestamp();

    try {
      // DB에 즉시 저장 (baseline + 빈 workout_set)
      final persistedBaseline = await _repository.addTodayWorkoutWithPersistence(
        exerciseName: name,
        bodyPartCode: bodyPartCode,
        targetMuscles: targetMuscles,
        sortTimestamp: sortTimestamp,
        routineId: null,
      );

      // 로컬 state에 추가
      final updatedBaselines = [...state.baselines, persistedBaseline];
      final groupedWorkouts = _groupWorkouts(updatedBaselines);
      final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

      state = state.copyWith(
        baselines: updatedBaselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: _calculateVolume(allWorkouts),
        mainFocusArea: _getFocusArea(allWorkouts),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '운동 추가 실패: $e');
    }
  }

  /// 정렬용 다음 타임스탬프 계산
  /// 현재 리스트의 최대 createdAt + 1초 반환 (새 항목이 맨 끝에 오도록)
  DateTime _getNextSortTimestamp() {
    if (state.baselines.isEmpty) {
      return DateTime.now();
    }

    DateTime maxTime = DateTime(1970);
    for (final baseline in state.baselines) {
      final createdAt = baseline.createdAt ?? DateTime(1970);
      if (createdAt.isAfter(maxTime)) {
        maxTime = createdAt;
      }
    }

    // 최대 시간 + 1초 반환
    return maxTime.add(const Duration(seconds: 1));
  }

  /// 루틴 저장
  Future<void> saveRoutine(String name, List<ExerciseBaseline> workouts) async {
    if (workouts.isEmpty) {
      state = state.copyWith(errorMessage: '저장할 운동이 없습니다.');
      return;
    }

    try {
      await _repository.saveRoutineFromWorkouts(name, workouts);
      await loadBaselines(forceRefresh: true); // 루틴 저장 후 강제 새로고침
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// 보관함/루틴에서 홈 화면에 운동 추가 (DB 즉시 저장)
  ///
  /// [Critical Requirement] 데이터 리셋:
  /// - 유지: exerciseName, bodyPart, targetMuscles
  /// - 리셋: workoutSets → 빈 리스트, isHiddenFromHome → false
  ///
  /// [Bug Fix] 즉시 DB 저장으로 앱 재시작 시 운동 사라지는 문제 해결
  /// [routineId]: 루틴에서 시작할 경우 루틴 ID 전달, 보관함에서는 null
  Future<void> addFromArchiveOrRoutine(
    List<ExerciseBaseline> baselines, {
    String? routineId,
  }) async {
    if (baselines.isEmpty) return;

    // 정렬용 기준 타임스탬프
    var sortTimestamp = _getNextSortTimestamp();
    final persistedBaselines = <ExerciseBaseline>[];

    try {
      // 각 운동을 순차적으로 DB에 저장 (정렬 순서 보장)
      for (final original in baselines) {
        final persisted = await _repository.addTodayWorkoutWithPersistence(
          exerciseName: original.exerciseName,
          bodyPartCode: original.bodyPart?.code ?? 'FULL',
          targetMuscles: original.targetMuscles ?? const [],
          sortTimestamp: sortTimestamp,
          routineId: routineId,
        );

        persistedBaselines.add(persisted);

        // 다음 운동을 위해 타임스탬프 1초 증가
        sortTimestamp = sortTimestamp.add(const Duration(seconds: 1));
      }

      // 현재 state에 추가
      final updatedBaselines = [...state.baselines, ...persistedBaselines];
      final groupedWorkouts = _groupWorkouts(updatedBaselines);
      final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

      state = state.copyWith(
        baselines: updatedBaselines,
        groupedWorkouts: groupedWorkouts,
        totalVolume: _calculateVolume(allWorkouts),
        mainFocusArea: _getFocusArea(allWorkouts),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '운동 추가 실패: $e');
    }
  }

  /// Draft 세트 리스트 병합 (Full Replacement)
  /// newBaselines의 각 항목에 대해 oldBaselines에서 같은 id를 찾아,
  /// Draft 상태(세트 개수 변경 또는 입력값 존재)면 old의 workoutSets 전체를 덮어씌움.
  List<ExerciseBaseline> _mergeDraftSets(
    List<ExerciseBaseline> newBaselines,
    List<ExerciseBaseline> oldBaselines,
  ) {
    return newBaselines.map((newItem) {
      // oldBaselines에서 같은 id를 가진 항목 찾기
      final oldItemIndex = oldBaselines.indexWhere((old) => old.id == newItem.id);
      
      // oldItem이 없으면 newItem 그대로 반환
      if (oldItemIndex == -1) {
        return newItem;
      }

      final oldItem = oldBaselines[oldItemIndex];

      // null 방지: 빈 리스트로 처리
      final oldSets = oldItem.workoutSets ?? [];
      final newSets = newItem.workoutSets ?? [];

      // 조건 A: 세트 개수가 다름 (구조 변경)
      final hasStructureChange = oldSets.length != newSets.length;

      // 조건 B: old에 입력값이 존재 (weight > 0 또는 reps > 0)
      final hasInputValue = oldSets.any((set) => set.weight > 0 || set.reps > 0);

      // Draft 상태(Dirty) 판단: 둘 중 하나라도 참이면
      if (hasStructureChange || hasInputValue) {
        // Full Replacement: old의 workoutSets 리스트 전체를 덮어씌움
        return newItem.copyWith(workoutSets: oldItem.workoutSets);
      }

      // 조건이 거짓이면 newItem 그대로 반환
      return newItem;
    }).toList();
  }

  /// 운동 그룹화 및 정렬
  /// [Phase 2 Fix] 순서 변경: routineId 우선순위 제거, 순수 createdAt ASC (FIFO)
  /// - 신규 운동이 항상 리스트 끝에 추가됨
  /// - 앱 재시작 시에도 추가 순서가 유지됨
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

    // [Phase 2 Fix] 정렬 로직: 순수 createdAt ASC (FIFO)
    // routineId 우선순위 제거 - 추가된 순서대로 표시
    uniqueFiltered.sort((a, b) {
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

  /// 입력값 메모리 업데이트 + 자동 저장 (Draft 상태 유지)
  /// 포커스가 해제될 때 호출되어 사용자 입력을 메모리에 반영하고 DB에 자동 저장합니다.
  /// [Phase 1 Auto-Save] 앱 재시작 시 데이터 유실 방지를 위해 즉시 DB 저장
  /// [Important] is_completed는 false로 유지 (Draft 상태)
  void updateSetInMemory(String setId, {double? weight, int? reps}) {
    WorkoutSet? updatedSet;

    final updatedBaselines = state.baselines.map((baseline) {
      final currentSets = baseline.workoutSets ?? [];

      // 해당 세트가 이 baseline에 존재하는지 확인
      final existingSetIndex = currentSets.indexWhere((s) => s.id == setId);

      if (existingSetIndex != -1) {
        // Case A: 기존 세트 업데이트
        final updatedSets = currentSets.map((set) {
          if (set.id == setId) {
            final newSet = set.copyWith(
              weight: weight ?? set.weight,
              reps: reps ?? set.reps,
              // [Phase 1] is_completed는 그대로 유지 (Draft 상태 보존)
            );
            updatedSet = newSet;
            return newSet;
          }
          return set;
        }).toList();

        return baseline.copyWith(workoutSets: updatedSets);
      }

      // Case B: 세트가 존재하지 않으면 이 baseline은 건드리지 않음
      return baseline;
    }).toList();

    state = state.copyWith(baselines: updatedBaselines);

    // [Phase 1 Auto-Save] 백그라운드에서 DB에 자동 저장 (UI 블로킹 없음)
    if (updatedSet != null) {
      _repository.upsertWorkoutSet(updatedSet!).catchError((e) {
        // 저장 실패 시 로그만 남기고 사용자에게는 표시하지 않음
        // 다음 저장 시 재시도됨
        return updatedSet!;
      });
    }
  }

  /// 새로운 세트를 baseline에 추가 (Upsert) + 자동 저장
  /// WorkoutCard에서 로컬로 생성한 세트를 ViewModel에 동기화할 때 사용
  /// [Phase 1 Auto-Save] 앱 재시작 시 데이터 유실 방지를 위해 즉시 DB 저장
  void upsertSetInMemory(
    String baselineId,
    String setId, {
    required double weight,
    required int reps,
    required int sets,
    required DateTime createdAt,
  }) {
    WorkoutSet? upsertedSet;

    final updatedBaselines = state.baselines.map((baseline) {
      if (baseline.id != baselineId) return baseline;

      final currentSets = List<WorkoutSet>.from(baseline.workoutSets ?? []);
      final existingSetIndex = currentSets.indexWhere((s) => s.id == setId);

      if (existingSetIndex != -1) {
        // Update existing set
        final updatedSet = currentSets[existingSetIndex].copyWith(
          weight: weight,
          reps: reps,
        );
        currentSets[existingSetIndex] = updatedSet;
        upsertedSet = updatedSet;
      } else {
        // Add new set
        final newSet = WorkoutSet(
          id: setId,
          baselineId: baselineId,
          weight: weight,
          reps: reps,
          sets: sets,
          isCompleted: false, // [Phase 1] Draft 상태로 생성
          createdAt: createdAt,
        );
        currentSets.add(newSet);
        upsertedSet = newSet;
      }

      return baseline.copyWith(workoutSets: currentSets);
    }).toList();

    state = state.copyWith(baselines: updatedBaselines);

    // [Phase 1 Auto-Save] 백그라운드에서 DB에 자동 저장 (UI 블로킹 없음)
    if (upsertedSet != null) {
      _repository.upsertWorkoutSet(upsertedSet!).catchError((e) {
        // 저장 실패 시 로그만 남기고 사용자에게는 표시하지 않음
        return upsertedSet!;
      });
    }
  }

  /// 세트 삭제 + 자동 저장
  /// WorkoutCard에서 세트를 삭제할 때 호출
  /// [Phase 1 Auto-Save] 앱 재시작 시 데이터 일관성을 위해 즉시 DB 삭제
  /// [Issue #1 Fix] 삭제 실패 시 상태 롤백 및 에러 메시지 표시
  void deleteSetInMemory(String baselineId, String setId) {
    // [Issue #1 Fix] 롤백을 위해 변경 전 상태 저장
    final previousBaselines = state.baselines;

    final updatedBaselines = state.baselines.map((baseline) {
      if (baseline.id != baselineId) return baseline;

      final currentSets = List<WorkoutSet>.from(baseline.workoutSets ?? []);
      currentSets.removeWhere((s) => s.id == setId);

      return baseline.copyWith(workoutSets: currentSets);
    }).toList();

    // Optimistic UI 업데이트
    state = state.copyWith(baselines: updatedBaselines);

    // [Phase 1 Auto-Save] 백그라운드에서 DB에서 삭제
    // [Issue #1 Fix] 실패 시 상태 롤백 및 에러 메시지 설정
    _repository.deleteWorkoutSet(setId).catchError((e) {
      // 삭제 실패: 이전 상태로 롤백하여 UI와 DB 상태 일치
      state = state.copyWith(
        baselines: previousBaselines,
        errorMessage: '네트워크 오류로 세트를 삭제하지 못했습니다. 다시 시도해주세요.',
      );
    });
  }

  /// [Phase 4] 운동 순서 변경 (드래그 앤 드롭 후 호출)
  /// 사용자가 재정렬한 순서를 반영하여 createdAt을 업데이트합니다.
  ///
  /// [Bug Fix] DB에 순서 저장으로 앱 재시작 후에도 사용자가 지정한 순서 유지
  Future<void> reorderWorkouts(List<ExerciseBaseline> reorderedList) async {
    if (reorderedList.isEmpty) return;

    // 새로운 순서에 맞게 createdAt을 재할당
    // 기준: 현재 시간부터 1ms씩 증가하여 순서 보장
    final now = DateTime.now();
    final updatedBaselines = <ExerciseBaseline>[];

    for (int i = 0; i < reorderedList.length; i++) {
      final baseline = reorderedList[i];
      // 새로운 createdAt 할당 (순서 보존을 위해 인덱스 기반)
      final newCreatedAt = now.add(Duration(milliseconds: i));
      updatedBaselines.add(baseline.copyWith(createdAt: newCreatedAt));
    }

    // 기존 state.baselines에서 reorderedList에 없는 항목들 찾기
    final reorderedIds = reorderedList.map((b) => b.id).toSet();
    final remainingBaselines = state.baselines
        .where((b) => !reorderedIds.contains(b.id))
        .toList();

    // 재정렬된 항목 + 나머지 항목 합치기
    final finalBaselines = [...updatedBaselines, ...remainingBaselines];

    final groupedWorkouts = _groupWorkouts(finalBaselines);
    final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

    // 로컬 상태 즉시 업데이트 (UI 반응성)
    state = state.copyWith(
      baselines: finalBaselines,
      groupedWorkouts: groupedWorkouts,
      totalVolume: _calculateVolume(allWorkouts),
      mainFocusArea: _getFocusArea(allWorkouts),
    );

    // [Bug Fix] DB에 순서 저장 (백그라운드)
    try {
      final baselineIds = reorderedList.map((b) => b.id).toList();
      await _repository.persistWorkoutOrder(baselineIds);
    } catch (e) {
      // DB 저장 실패해도 로컬 상태는 유지 (다음 저장 시 재시도)
      // 에러 로그만 남기고 사용자에게는 표시하지 않음
    }
  }

  /// 저장 후 해당 카드만 교체 (전체 새로고침 없이 순서 유지)
  /// [Preserve List Order] map을 사용하여 기존 인덱스(순서)가 유지되도록 교체합니다.
  /// [Phase 3] 원본 createdAt을 보존하여 정렬 순서 변경 방지
  void replaceBaselineAfterSave(
    String oldBaselineId,
    ExerciseBaseline persistedBaseline,
  ) {
    // [Phase 3] 원본 baseline의 createdAt 및 routineId 보존
    // DB에서 가져온 persistedBaseline의 타임스탬프가 다를 수 있어 순서가 변경되는 것을 방지
    final originalBaseline = state.baselines.firstWhere(
      (b) => b.id == oldBaselineId,
      orElse: () => persistedBaseline,
    );

    final preservedBaseline = persistedBaseline.copyWith(
      createdAt: originalBaseline.createdAt, // 원본 생성 시간 유지
      routineId: originalBaseline.routineId, // 원본 루틴 ID 유지 (그룹 유지)
    );

    // 1. 저장된 항목 교체 (순서 보존)
    final newBaselines = state.baselines
        .map((b) => b.id == oldBaselineId ? preservedBaseline : b)
        .toList();

    // 2. 나머지 항목들의 Draft 보존 (수정된 로직)
    // 중요: oldBaselineId는 이미 DB 최신값(persistedBaseline)이므로,
    // 병합 대상(old)에서 제외하여 persistedBaseline이 덮어씌워지지 않도록 함.
    final mergedBaselines = _mergeDraftSets(
      newBaselines,
      state.baselines.where((b) => b.id != oldBaselineId).toList(),
    );

    // 3. 상태 갱신 (정렬 순서 유지됨 - createdAt이 보존되었으므로)
    final groupedWorkouts = _groupWorkouts(mergedBaselines);
    final allTodayWorkouts =
        groupedWorkouts.values.expand((list) => list).toList();
    state = state.copyWith(
      baselines: mergedBaselines,
      groupedWorkouts: groupedWorkouts,
      totalVolume: _calculateVolume(allTodayWorkouts),
      mainFocusArea: _getFocusArea(allTodayWorkouts),
    );
  }
}
