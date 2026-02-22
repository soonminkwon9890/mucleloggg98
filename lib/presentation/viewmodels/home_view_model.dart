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
  /// - 오늘 날짜: 메모리 전용 Draft로 홈 화면에 즉시 추가
  /// - 미래 날짜: planned_workouts 테이블에 저장 (캘린더에만 표시, 홈 화면에는 표시 안 함)
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

    // BodyPart enum 변환
    BodyPart? bodyPart;
    try {
      bodyPart = BodyPart.values.firstWhere(
        (bp) => bp.code == bodyPartCode,
        orElse: () => BodyPart.full,
      );
    } catch (e) {
      bodyPart = BodyPart.full;
    }

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

    // [기존 로직] 오늘 날짜인 경우: 메모리 전용 Draft로 홈 화면에 추가
    final newBaseline = ExerciseBaseline(
      id: _uuid.v4(),
      userId: userId,
      exerciseName: name,
      targetMuscles: targetMuscles,
      bodyPart: bodyPart,
      workoutSets: const [],
      routineId: null,
      isHiddenFromHome: false,
      createdAt: selectedDate,
      updatedAt: selectedDate,
    );

    final updatedBaselines = [...state.baselines, newBaseline];
    final groupedWorkouts = _groupWorkouts(updatedBaselines);
    final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

    state = state.copyWith(
      baselines: updatedBaselines,
      groupedWorkouts: groupedWorkouts,
      totalVolume: _calculateVolume(allWorkouts),
      mainFocusArea: _getFocusArea(allWorkouts),
    );
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

  /// 보관함/루틴에서 홈 화면에 운동 추가 (메모리 전용, DB 저장 X)
  ///
  /// [Critical Requirement] 데이터 리셋:
  /// - 유지: exerciseName, bodyPart, targetMuscles
  /// - 리셋: workoutSets → 빈 리스트, isHiddenFromHome → false
  /// - 새 UUID 생성 (DB 충돌 방지)
  ///
  /// [routineId]: 루틴에서 시작할 경우 루틴 ID 전달, 보관함에서는 null
  void addFromArchiveOrRoutine(
    List<ExerciseBaseline> baselines, {
    String? routineId,
  }) {
    if (baselines.isEmpty) return;

    final now = DateTime.now();

    // 새로운 baseline 생성 (데이터 리셋 + 새 UUID)
    final newBaselines = baselines.map((original) {
      return ExerciseBaseline(
        id: _uuid.v4(), // 새 UUID 생성
        userId: original.userId,
        exerciseName: original.exerciseName,
        targetMuscles: original.targetMuscles,
        bodyPart: original.bodyPart,
        videoUrl: original.videoUrl,
        thumbnailUrl: original.thumbnailUrl,
        skeletonData: original.skeletonData,
        feedbackPrompt: original.feedbackPrompt,
        workoutSets: const [], // 리셋: 빈 리스트
        routineId: routineId, // 루틴 ID 또는 null
        isHiddenFromHome: false, // 홈에 표시
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // 현재 state에 추가 (메모리 전용)
    final updatedBaselines = [...state.baselines, ...newBaselines];
    final groupedWorkouts = _groupWorkouts(updatedBaselines);
    final allWorkouts = groupedWorkouts.values.expand((list) => list).toList();

    state = state.copyWith(
      baselines: updatedBaselines,
      groupedWorkouts: groupedWorkouts,
      totalVolume: _calculateVolume(allWorkouts),
      mainFocusArea: _getFocusArea(allWorkouts),
    );
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

  /// 입력값 메모리 업데이트 (DB 호출 X, 화면 갱신만 수행)
  /// 포커스가 해제될 때 호출되어 사용자 입력을 메모리에 반영합니다.
  /// [Fix] Upsert 로직으로 변경 - 세트가 없으면 추가, 있으면 업데이트
  void updateSetInMemory(String setId, {double? weight, int? reps}) {
    final updatedBaselines = state.baselines.map((baseline) {
      final currentSets = baseline.workoutSets ?? [];

      // 해당 세트가 이 baseline에 존재하는지 확인
      final existingSetIndex = currentSets.indexWhere((s) => s.id == setId);

      if (existingSetIndex != -1) {
        // Case A: 기존 세트 업데이트
        final updatedSets = currentSets.map((set) {
          if (set.id == setId) {
            return set.copyWith(
              weight: weight ?? set.weight,
              reps: reps ?? set.reps,
            );
          }
          return set;
        }).toList();

        return baseline.copyWith(workoutSets: updatedSets);
      }

      // Case B: 세트가 존재하지 않으면 이 baseline은 건드리지 않음
      return baseline;
    }).toList();

    state = state.copyWith(baselines: updatedBaselines);
  }

  /// 새로운 세트를 baseline에 추가 (Upsert)
  /// WorkoutCard에서 로컬로 생성한 세트를 ViewModel에 동기화할 때 사용
  void upsertSetInMemory(
    String baselineId,
    String setId, {
    required double weight,
    required int reps,
    required int sets,
    required DateTime createdAt,
  }) {
    final updatedBaselines = state.baselines.map((baseline) {
      if (baseline.id != baselineId) return baseline;

      final currentSets = List<WorkoutSet>.from(baseline.workoutSets ?? []);
      final existingSetIndex = currentSets.indexWhere((s) => s.id == setId);

      if (existingSetIndex != -1) {
        // Update existing set
        currentSets[existingSetIndex] = currentSets[existingSetIndex].copyWith(
          weight: weight,
          reps: reps,
        );
      } else {
        // Add new set
        currentSets.add(WorkoutSet(
          id: setId,
          baselineId: baselineId,
          weight: weight,
          reps: reps,
          sets: sets,
          isCompleted: false,
          createdAt: createdAt,
        ));
      }

      return baseline.copyWith(workoutSets: currentSets);
    }).toList();

    state = state.copyWith(baselines: updatedBaselines);
  }

  /// 저장 후 해당 카드만 교체 (전체 새로고침 없이 순서 유지)
  /// [Preserve List Order] map을 사용하여 기존 인덱스(순서)가 유지되도록 교체합니다.
  void replaceBaselineAfterSave(
    String oldBaselineId,
    ExerciseBaseline persistedBaseline,
  ) {
    // 1. 저장된 항목 교체 (기존 로직)
    final newBaselines = state.baselines
        .map((b) => b.id == oldBaselineId ? persistedBaseline : b)
        .toList();

    // 2. 나머지 항목들의 Draft 보존 (수정된 로직)
    // 중요: oldBaselineId는 이미 DB 최신값(persistedBaseline)이므로,
    // 병합 대상(old)에서 제외하여 persistedBaseline이 덮어씌워지지 않도록 함.
    final mergedBaselines = _mergeDraftSets(
      newBaselines,
      state.baselines.where((b) => b.id != oldBaselineId).toList(),
    );

    // 3. 상태 갱신
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
