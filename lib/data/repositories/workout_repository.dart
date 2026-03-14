import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/exercise_with_history.dart';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import '../models/check_point.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';
import '../models/workout_session.dart';
import '../models/planned_workout.dart';
import '../models/workout_completion_input.dart';
import '../../core/enums/exercise_enums.dart';

// 분리된 레포지토리들 import
import 'base_repository.dart';
import 'exercise_repository.dart';
import 'workout_set_repository.dart';
import 'planned_workout_repository.dart';
import 'routine_repository.dart';
import 'workout_stats_repository.dart';

/// 운동 데이터 레포지토리 (Facade)
///
/// 이 클래스는 분리된 여러 레포지토리들을 통합하여 기존 API를 유지합니다.
/// 모든 메서드는 적절한 하위 레포지토리로 위임됩니다.
class WorkoutRepository with BaseRepositoryMixin {
  // 분리된 레포지토리 인스턴스들
  final ExerciseRepository _exerciseRepo = ExerciseRepository();
  final WorkoutSetRepository _setRepo = WorkoutSetRepository();
  final PlannedWorkoutRepository _plannedRepo = PlannedWorkoutRepository();
  final RoutineRepository _routineRepo = RoutineRepository();
  final WorkoutStatsRepository _statsRepo = WorkoutStatsRepository();

  // ============================================
  // Exercise (Baseline) 관련 메서드
  // ============================================

  /// 운동 기준 정보 저장/수정 통합 (Upsert)
  Future<ExerciseBaseline> upsertBaseline(ExerciseBaseline baseline) =>
      _exerciseRepo.upsertBaseline(baseline);

  /// [Deprecated] 운동 기준 정보 저장
  @Deprecated('Use upsertBaseline instead')
  Future<ExerciseBaseline> saveBaseline(ExerciseBaseline baseline) async =>
      upsertBaseline(baseline.copyWith(id: const Uuid().v4()));

  /// 사용자의 모든 운동 기준 정보 가져오기
  Future<List<ExerciseBaseline>> getBaselines() => _exerciseRepo.getBaselines();

  /// 오늘 날짜의 운동 기준 정보 가져오기
  Future<List<ExerciseBaseline>> getTodayBaselines() => _statsRepo.getTodayBaselines();

  /// 날짜 변경 시 홈 화면 초기화
  Future<void> resetHomeForNewDay() => _statsRepo.resetHomeForNewDay();

  /// 보관함용 운동 목록 조회
  Future<List<ExerciseBaseline>> getArchivedBaselines() =>
      _exerciseRepo.getArchivedBaselines();

  /// 특정 운동 기준 정보 가져오기
  Future<ExerciseBaseline?> getBaselineById(String baselineId) =>
      _exerciseRepo.getBaselineById(baselineId);

  /// 같은 이름/부위/타입의 운동이 있는지 확인
  Future<ExerciseBaseline?> findDuplicateBaseline({
    required String exerciseName,
    required String? bodyPart,
  }) =>
      _exerciseRepo.findDuplicateBaseline(
        exerciseName: exerciseName,
        bodyPart: bodyPart,
      );

  /// 운동 추가/활성화 통합 메서드
  Future<ExerciseBaseline> ensureExerciseVisible(
    String name,
    String bodyPartCode,
    List<String> targetMuscles,
  ) =>
      _exerciseRepo.ensureExerciseVisible(
        name,
        bodyPartCode,
        targetMuscles,
        recoverCallback: (baselineId) =>
            _setRepo.recoverOrAddExercise(baselineId, currentUserId),
      );

  /// [Deprecated] 기존 운동의 상태 업데이트
  @Deprecated('Use upsertBaseline instead')
  Future<void> updateBaseline(ExerciseBaseline baseline) async =>
      await upsertBaseline(baseline);

  /// Baseline의 영상 URL 업데이트
  Future<void> updateBaselineVideo(
    String baselineId,
    String videoUrl,
    String? thumbnailUrl,
  ) =>
      _exerciseRepo.updateBaselineVideo(baselineId, videoUrl, thumbnailUrl);

  /// 영상 파일 업로드
  Future<String> uploadVideo(File videoFile, String baselineId) =>
      _exerciseRepo.uploadVideo(videoFile, baselineId);

  /// 썸네일 이미지 업로드
  Future<String> uploadThumbnail(File thumbnailFile, String baselineId) =>
      _exerciseRepo.uploadThumbnail(thumbnailFile, baselineId);

  /// 운동 삭제
  Future<void> deleteBaseline(String baselineId, String exerciseName) =>
      _exerciseRepo.deleteBaseline(baselineId, exerciseName);

  /// ID 목록으로 운동 정보 일괄 조회
  Future<List<ExerciseBaseline>> getBaselinesByIds(List<String> ids) =>
      _exerciseRepo.getBaselinesByIds(ids);

  /// 운동 이름 변경
  Future<void> updateExerciseName(String oldName, String newName) =>
      _exerciseRepo.updateExerciseName(oldName, newName);

  /// 운동 순서 변경 DB 저장
  Future<void> persistWorkoutOrder(List<String> baselineIds) =>
      _exerciseRepo.persistWorkoutOrder(baselineIds);

  // ============================================
  // WorkoutSet 관련 메서드
  // ============================================

  /// [Deprecated] 운동 세트 기록 저장
  @Deprecated('Use upsertWorkoutSet instead')
  Future<WorkoutSet> saveWorkoutSet(WorkoutSet workoutSet) =>
      upsertWorkoutSet(workoutSet);

  /// 특정 운동의 모든 세트 기록 가져오기
  Future<List<WorkoutSet>> getWorkoutSets(String baselineId) =>
      _setRepo.getWorkoutSets(baselineId);

  /// 최근 세트 기록 가져오기
  Future<WorkoutSet?> getLatestWorkoutSet(String baselineId) =>
      _setRepo.getLatestWorkoutSet(baselineId);

  /// WorkoutSet Upsert
  Future<WorkoutSet> upsertWorkoutSet(WorkoutSet set) =>
      _setRepo.upsertWorkoutSet(set);

  /// 세트 일괄 저장
  Future<void> batchSaveWorkoutSets(List<WorkoutSet> sets) =>
      _setRepo.batchSaveWorkoutSets(sets);

  /// [Deprecated] 세트 수정
  @Deprecated('Use upsertWorkoutSet instead')
  Future<WorkoutSet> updateWorkoutSet(WorkoutSet set) => upsertWorkoutSet(set);

  /// 세트 삭제
  Future<void> deleteWorkoutSet(String setId) => _setRepo.deleteWorkoutSet(setId);

  /// 오늘 날짜의 특정 운동 세트 기록 조회
  Future<List<WorkoutSet>> getTodayWorkoutSets(String baselineId) =>
      _setRepo.getTodayWorkoutSets(baselineId);

  /// 특정 날짜의 세트 기록 삭제 (Soft Delete)
  Future<void> deleteWorkoutSetsByDate(String baselineId, DateTime date) async {
    final userId = currentUserId;
    await ensureProfileExists();

    // 보안 검증
    final baselineCheck = await client
        .from('exercise_baselines')
        .select('id')
        .eq('id', baselineId)
        .eq('user_id', userId)
        .maybeSingle();

    if (baselineCheck == null) {
      throw Exception('해당 운동을 찾을 수 없거나 권한이 없습니다.');
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    final existingSets = await client
        .from('workout_sets')
        .select('id, is_completed')
        .eq('baseline_id', baselineId)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    if ((existingSets as List).isNotEmpty) {
      await _setRepo.deleteWorkoutSetsByDate(baselineId, date);

      await client
          .from('exercise_baselines')
          .update({
            'is_hidden_from_home': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', baselineId)
          .eq('user_id', userId);
    }
  }

  /// 오늘의 운동 세션 삭제
  Future<void> deleteTodayWorkoutsByBaseline(String baselineId) async {
    final userId = currentUserId;

    await _setRepo.deleteTodaySets(baselineId);

    await client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 운동 추가/복구 로직
  Future<bool> recoverOrAddExercise(String baselineId) =>
      _setRepo.recoverOrAddExercise(baselineId, currentUserId);

  /// 과거 날짜의 세트 데이터를 오늘 날짜로 복사
  Future<void> copySetsToToday(String baselineId, List<WorkoutSet> pastSets) =>
      _setRepo.copySetsToToday(baselineId, pastSets, currentUserId);

  /// 중간 점검 데이터 저장
  Future<CheckPoint> saveCheckPoint(CheckPoint checkPoint) =>
      _setRepo.saveCheckPoint(checkPoint);

  /// 특정 운동의 중간 점검 데이터 가져오기
  Future<List<CheckPoint>> getCheckPoints(String baselineId) =>
      _setRepo.getCheckPoints(baselineId);

  // ============================================
  // PlannedWorkout 관련 메서드
  // ============================================

  /// 주간 계획 일괄 저장
  Future<void> savePlannedWorkouts(List<PlannedWorkout> plans) =>
      _plannedRepo.savePlannedWorkouts(plans);

  /// 날짜 범위 내의 계획된 운동 조회
  Future<List<PlannedWorkout>> getPlannedWorkoutsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _plannedRepo.getPlannedWorkoutsByDateRange(startDate, endDate);

  /// 날짜 범위 내의 계획된 운동 조회 (운동 이름 포함)
  /// [activeOnly] true이면 변환되지 않은(아직 실행 안 된) 운동만 반환 (D.4 최적화)
  Future<(List<PlannedWorkout>, Map<String, String>)>
      getPlannedWorkoutsByDateRangeWithNames(
    DateTime startDate,
    DateTime endDate, {
    bool activeOnly = false,
  }) =>
          _plannedRepo.getPlannedWorkoutsByDateRangeWithNames(
            startDate,
            endDate,
            activeOnly: activeOnly,
          );

  /// 계획된 운동 완료 상태 토글
  Future<void> togglePlannedWorkoutCompletion(String id, bool isCompleted) =>
      _plannedRepo.togglePlannedWorkoutCompletion(id, isCompleted);

  /// 계획된 운동 삭제
  Future<void> deletePlannedWorkout(String id) =>
      _plannedRepo.deletePlannedWorkout(id);

  /// 계획된 운동 수정
  Future<void> updatePlannedWorkout(
    String id, {
    required double targetWeight,
    required int targetReps,
    required String colorHex,
    String? aiComment,
  }) =>
      _plannedRepo.updatePlannedWorkout(
        id,
        targetWeight: targetWeight,
        targetReps: targetReps,
        colorHex: colorHex,
        aiComment: aiComment,
      );

  /// 계획된 운동의 날짜만 수정
  Future<void> updatePlannedWorkoutDate(String id, DateTime newDate) =>
      _plannedRepo.updatePlannedWorkoutDate(id, newDate);

  /// 계획된 운동을 완료 처리하고 WorkoutSet으로 변환
  Future<void> completeAndConvertPlannedWorkouts(
    List<WorkoutCompletionInput> inputs,
    List<PlannedWorkout> originalPlans,
  ) =>
      _plannedRepo.completeAndConvertPlannedWorkouts(inputs, originalPlans);

  /// 특정 날짜의 계획된 운동을 ExerciseBaseline 형태로 변환
  Future<(List<ExerciseBaseline>, Map<String, PlannedWorkout>)>
      getPlannedWorkoutsAsBaselines(DateTime date) =>
          _plannedRepo.getPlannedWorkoutsAsBaselines(date);

  /// 계획된 운동을 로그로 변환 완료 처리
  Future<void> markPlannedWorkoutAsConverted(String plannedWorkoutId) =>
      _plannedRepo.markPlannedWorkoutAsConverted(plannedWorkoutId);

  /// 지난 주 운동을 다음 주로 복사
  Future<int> duplicatePastWeekToNextWeek(String colorHex) =>
      _plannedRepo.duplicatePastWeekToNextWeek(colorHex);

  // ============================================
  // Routine 관련 메서드
  // ============================================

  /// 루틴 저장
  Future<Routine> saveRoutine(Routine routine, List<RoutineItem> items) =>
      _routineRepo.saveRoutine(routine, items);

  /// 사용자의 모든 루틴 조회
  Future<List<Routine>> getRoutines() => _routineRepo.getRoutines();

  /// 특정 루틴 조회
  Future<Routine?> getRoutineById(String id) => _routineRepo.getRoutineById(id);

  /// 루틴 수정
  Future<Routine> updateRoutine(
    String id,
    Routine routine,
    List<RoutineItem> items,
  ) =>
      _routineRepo.updateRoutine(id, routine, items);

  /// 루틴 이름만 수정
  Future<void> updateRoutineName(String routineId, String newName) =>
      _routineRepo.updateRoutineName(routineId, newName);

  /// 루틴에서 개별 운동 삭제
  Future<void> removeExerciseFromRoutine(String routineItemId) =>
      _routineRepo.removeExerciseFromRoutine(routineItemId);

  /// 루틴 내 운동 순서 변경
  Future<void> updateRoutineItemOrder(String routineId, List<String> newOrder) =>
      _routineRepo.updateRoutineItemOrder(routineId, newOrder);

  /// 루틴 삭제
  Future<void> deleteRoutine(String routineId) =>
      _routineRepo.deleteRoutine(routineId);

  /// 루틴에 운동 추가
  Future<void> addExercisesToRoutine(
    String routineId,
    List<String> baselineIds,
  ) =>
      _routineRepo.addExercisesToRoutine(
        routineId,
        baselineIds,
        () => getBaselines(),
      );

  /// 특정 운동이 포함된 루틴 조회
  Future<List<Routine>> getRoutinesByExerciseName(String exerciseName) =>
      _routineRepo.getRoutinesByExerciseName(exerciseName);

  /// 루틴 실행 이력 조회
  Future<Map<String, List<ExerciseBaseline>>> getRoutineExecutionHistory(
    String routineId,
  ) =>
      _routineRepo.getRoutineExecutionHistory(routineId);

  /// 홈 화면 운동들을 루틴으로 일괄 저장
  Future<void> saveRoutineFromWorkouts(
    String routineName,
    List<ExerciseBaseline> baselines,
  ) =>
      _routineRepo.saveRoutineFromWorkouts(routineName, baselines);

  // ============================================
  // Stats/Analytics 관련 메서드
  // ============================================

  /// 사용자의 운동 날짜 목록 가져오기
  Future<List<DateTime>> getWorkoutDates() => _statsRepo.getWorkoutDates();

  /// 특정 날짜의 운동 기록 가져오기
  Future<List<ExerciseBaseline>> getWorkoutsByDate(
    DateTime date, {
    bool completedOnly = false,
  }) =>
      _statsRepo.getWorkoutsByDate(date, completedOnly: completedOnly);

  /// 특정 baseline의 특정 날짜 완료 세트 조회
  Future<List<WorkoutSet>> getCompletedWorkoutSetsByBaselineIdForDate(
    String baselineId,
    DateTime date,
  ) =>
      _statsRepo.getCompletedWorkoutSetsByBaselineIdForDate(baselineId, date);

  /// 특정 운동의 날짜별 기록 조회
  Future<Map<String, List<WorkoutSet>>> getHistoryByExerciseName(
    String exerciseName,
  ) =>
      _statsRepo.getHistoryByExerciseName(exerciseName);

  /// 특정 주 주간 볼륨 조회
  Future<Map<DateTime, double>> getWeeklyVolume({DateTime? weekStart}) =>
      _statsRepo.getWeeklyVolume(weekStart: weekStart);

  /// 특정 주 부위 밸런스 집계
  Future<Map<String, double>> getBodyBalance({DateTime? weekStart}) =>
      _statsRepo.getBodyBalance(weekStart: weekStart);

  /// targetMuscles 문자열을 8개 카테고리로 매핑
  String mapMuscleToAxis(String muscle) => _statsRepo.mapMuscleToAxis(muscle);

  /// 특정 운동의 날짜별 강도 조회
  Future<Map<String, String?>> getDifficultyByExerciseName(
    String exerciseName,
  ) =>
      _statsRepo.getDifficultyByExerciseName(exerciseName);

  /// 특정 운동의 월별 기록 조회
  Future<Map<String, List<WorkoutSet>>> getWorkoutHistoryByExercise(
    String exerciseName,
  ) =>
      _statsRepo.getWorkoutHistoryByExercise(exerciseName);

  /// 완료된 운동 기록이 있는 운동 목록 + 수행 날짜 리스트 조회
  Future<List<ExerciseWithHistory>> getExercisesWithHistory() =>
      _statsRepo.getExercisesWithHistory();

  /// 특정 운동의 수행 일수 조회
  Future<int> getExerciseFrequency(String baselineId) =>
      _statsRepo.getExerciseFrequency(baselineId);

  /// 운동 세션 정보 저장
  Future<void> saveWorkoutSession({
    required String baselineId,
    required DateTime date,
    required String difficulty,
    double? totalVolume,
    int? durationMinutes,
  }) =>
      _statsRepo.saveWorkoutSession(
        baselineId: baselineId,
        date: date,
        difficulty: difficulty,
        totalVolume: totalVolume,
        durationMinutes: durationMinutes,
      );

  /// 이번 주 운동 세션 조회
  Future<List<WorkoutSession>> getLastWeekSessions() =>
      _statsRepo.getLastWeekSessions();

  /// 특정 날짜의 평균 무게/횟수 조회
  Future<(double weight, int reps)> getLastWeekAverageSets(
    String baselineId,
    DateTime date,
  ) =>
      _statsRepo.getLastWeekAverageSets(baselineId, date);

  /// 특정 날짜의 '최고 중량 세트' 조회
  Future<(double weight, int reps)> getLastWeekBestSet(
    String baselineId,
    DateTime date,
  ) =>
      _statsRepo.getLastWeekBestSet(baselineId, date);

  /// 사용자 운동 목표 조회
  Future<String> getUserGoal() => _statsRepo.getUserGoal();

  // ============================================
  // 복합 메서드 (여러 레포지토리 사용)
  // ============================================

  /// 당일 운동 추가
  Future<ExerciseBaseline> addTodayWorkout(
    ExerciseBaseline baseline, {
    double? initialWeight,
    int? initialReps,
    String? routineId,
  }) async {
    await ensureProfileExists();

    final existing = await getBaselineById(baseline.id);
    if (existing == null) {
      throw Exception('운동이 존재하지 않습니다. ensureExerciseVisible을 사용하여 먼저 운동을 생성/활성화하세요.');
    }

    final updatedBaseline = existing.copyWith(
      routineId: routineId,
      updatedAt: DateTime.now(),
    );

    final savedBaseline = await upsertBaseline(updatedBaseline);

    if (initialWeight != null || initialReps != null) {
      final initialSet = WorkoutSet(
        id: const Uuid().v4(),
        baselineId: savedBaseline.id,
        weight: initialWeight ?? 0.0,
        reps: initialReps ?? 0,
        sets: 1,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await upsertWorkoutSet(initialSet);
    }

    return await getBaselineById(savedBaseline.id) ?? savedBaseline;
  }

  /// 오늘의 운동에 즉시 추가 및 DB 저장
  Future<ExerciseBaseline> addTodayWorkoutWithPersistence({
    required String exerciseName,
    required String bodyPartCode,
    required List<String> targetMuscles,
    DateTime? sortTimestamp,
    String? routineId,
  }) async {
    final userId = currentUserId;
    await ensureProfileExists();

    final now = sortTimestamp ?? DateTime.now();
    final trimmedName = exerciseName.trim();

    final existingBaseline = await client
        .from('exercise_baselines')
        .select('*')
        .eq('user_id', userId)
        .ilike('exercise_name', trimmedName)
        .maybeSingle();

    ExerciseBaseline baseline;

    if (existingBaseline == null) {
      final newBaseline = ExerciseBaseline(
        id: const Uuid().v4(),
        userId: userId,
        exerciseName: trimmedName,
        bodyPart: BodyPartParsing.fromCode(bodyPartCode),
        targetMuscles: targetMuscles.isEmpty ? null : targetMuscles,
        routineId: routineId,
        isHiddenFromHome: false,
        createdAt: now,
        updatedAt: now,
      );
      baseline = await upsertBaseline(newBaseline);
    } else {
      final existing = ExerciseBaseline.fromJson(existingBaseline);

      await client
          .from('exercise_baselines')
          .update({
            'is_hidden_from_home': false,
            'routine_id': routineId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', existing.id)
          .eq('user_id', userId);

      await recoverOrAddExercise(existing.id);

      final updated = await getBaselineById(existing.id);
      baseline = updated ?? existing;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    final existingSets = await client
        .from('workout_sets')
        .select('id')
        .eq('baseline_id', baseline.id)
        .eq('is_hidden', false)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    if ((existingSets as List).isEmpty) {
      final emptySet = WorkoutSet(
        id: const Uuid().v4(),
        baselineId: baseline.id,
        weight: 0.0,
        reps: 0,
        sets: 1,
        isCompleted: false,
        createdAt: now,
      );
      await upsertWorkoutSet(emptySet);
    }

    return await getBaselineById(baseline.id) ?? baseline;
  }
}
