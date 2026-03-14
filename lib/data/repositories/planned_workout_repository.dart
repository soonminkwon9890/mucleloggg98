import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/planned_workout.dart';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import '../models/workout_completion_input.dart';
import 'base_repository.dart';
import 'workout_set_repository.dart';

/// 계획된 운동(PlannedWorkout) 레포지토리
///
/// planned_workouts 테이블 관련 CRUD 작업을 담당합니다.
class PlannedWorkoutRepository with BaseRepositoryMixin {
  final WorkoutSetRepository _setRepository = WorkoutSetRepository();

  /// 주간 계획 일괄 저장
  Future<void> savePlannedWorkouts(List<PlannedWorkout> plans) async {
    await ensureProfileExists();
    final userId = currentUserId;

    if (plans.isEmpty) return;

    final dataList = plans.map((plan) {
      final json = plan.toJson();
      json['user_id'] = userId;
      json['scheduled_date'] = DateFormat('yyyy-MM-dd').format(plan.scheduledDate);
      if (json['created_at'] != null && json['created_at'] is DateTime) {
        json['created_at'] = (json['created_at'] as DateTime).toIso8601String();
      }
      return json;
    }).toList();

    await client.from('planned_workouts').insert(dataList);
  }

  /// 날짜 범위 내의 계획된 운동 조회
  Future<List<PlannedWorkout>> getPlannedWorkoutsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = currentUserId;

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final response = await client
        .from('planned_workouts')
        .select()
        .eq('user_id', userId)
        .gte('scheduled_date', startStr)
        .lte('scheduled_date', endStr);

    return (response as List)
        .map((json) => PlannedWorkout.fromJson(json))
        .toList();
  }

  /// 날짜 범위 내의 계획된 운동 조회 (운동 이름 포함)
  ///
  /// [activeOnly] true이면 변환되지 않은(아직 실행 안 된) 운동만 반환 (D.4 최적화)
  Future<(List<PlannedWorkout>, Map<String, String>)> getPlannedWorkoutsByDateRangeWithNames(
    DateTime startDate,
    DateTime endDate, {
    bool activeOnly = false,
  }) async {
    final userId = currentUserId;

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    // D.4: DB 레벨에서 필터링하여 네트워크 트래픽 최적화
    var query = client
        .from('planned_workouts')
        .select('*, exercise_baselines(exercise_name)')
        .eq('user_id', userId)
        .gte('scheduled_date', startStr)
        .lte('scheduled_date', endStr);

    if (activeOnly) {
      query = query.eq('is_converted_to_log', false);
    }

    final response = await query;

    final plannedWorkouts = <PlannedWorkout>[];
    final exerciseNameMap = <String, String>{};

    for (final row in response as List) {
      final rowCopy = Map<String, dynamic>.from(row);
      final baselineData = rowCopy.remove('exercise_baselines');

      final plannedWorkout = PlannedWorkout.fromJson(rowCopy);
      plannedWorkouts.add(plannedWorkout);

      if (baselineData != null && baselineData is List && baselineData.isNotEmpty) {
        final exerciseName = baselineData[0]['exercise_name'] as String?;
        if (exerciseName != null) {
          exerciseNameMap[plannedWorkout.baselineId] = exerciseName;
        }
      }
    }

    return (plannedWorkouts, exerciseNameMap);
  }

  /// 계획된 운동 완료 상태 토글
  Future<void> togglePlannedWorkoutCompletion(String id, bool isCompleted) async {
    final userId = currentUserId;

    await client
        .from('planned_workouts')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동 삭제
  Future<void> deletePlannedWorkout(String id) async {
    final userId = currentUserId;

    await client
        .from('planned_workouts')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동 수정
  Future<void> updatePlannedWorkout(
    String id, {
    required double targetWeight,
    required int targetReps,
    required String colorHex,
    String? aiComment,
  }) async {
    final userId = currentUserId;

    await client
        .from('planned_workouts')
        .update({
          'target_weight': targetWeight,
          'target_reps': targetReps,
          'color_hex': colorHex,
          'ai_comment': aiComment,
        })
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동의 날짜만 수정
  Future<void> updatePlannedWorkoutDate(String id, DateTime newDate) async {
    final userId = currentUserId;

    final normalized = DateTime(newDate.year, newDate.month, newDate.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(normalized);

    await client
        .from('planned_workouts')
        .update({'scheduled_date': dateStr})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동을 완료 처리하고 WorkoutSet으로 변환
  Future<void> completeAndConvertPlannedWorkouts(
    List<WorkoutCompletionInput> inputs,
    List<PlannedWorkout> originalPlans,
  ) async {
    if (inputs.isEmpty) return;

    await ensureProfileExists();
    final userId = currentUserId;

    // 상태 업데이트
    final planIds = inputs.map((i) => i.plannedWorkoutId).toList();
    await client
        .from('planned_workouts')
        .update({
          'is_completed': true,
          'is_converted_to_log': true,
        })
        .eq('user_id', userId)
        .inFilter('id', planIds);

    // WorkoutSet 생성
    final planById = {for (final p in originalPlans) p.id: p};
    final workoutSets = <WorkoutSet>[];

    for (final input in inputs) {
      final plan = planById[input.plannedWorkoutId];
      if (plan == null) continue;

      final setsCount = input.actualSets > 0 ? input.actualSets : plan.targetSets;
      for (int idx = 0; idx < setsCount; idx++) {
        workoutSets.add(WorkoutSet(
          id: const Uuid().v4(),
          baselineId: plan.baselineId,
          weight: input.actualWeight,
          reps: input.actualReps,
          sets: idx + 1,
          isCompleted: true,
          createdAt: plan.scheduledDate,
        ));
      }
    }

    if (workoutSets.isNotEmpty) {
      await _setRepository.batchSaveWorkoutSets(workoutSets);
    }
  }

  /// 특정 날짜의 계획된 운동을 ExerciseBaseline 형태로 변환
  Future<(List<ExerciseBaseline>, Map<String, PlannedWorkout>)> getPlannedWorkoutsAsBaselines(
    DateTime date,
  ) async {
    final userId = currentUserId;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final response = await client
        .from('planned_workouts')
        .select('*, exercise_baselines(*)')
        .eq('user_id', userId)
        .eq('scheduled_date', dateStr)
        .eq('is_converted_to_log', false);

    if (response.isEmpty) {
      return (<ExerciseBaseline>[], <String, PlannedWorkout>{});
    }

    final resultBaselines = <ExerciseBaseline>[];
    final plannedWorkoutMap = <String, PlannedWorkout>{};

    for (final row in response as List) {
      final rowCopy = Map<String, dynamic>.from(row);
      final baselineData = rowCopy.remove('exercise_baselines');

      final plannedWorkout = PlannedWorkout.fromJson(rowCopy);

      if (baselineData == null) continue;

      final baseline = ExerciseBaseline.fromJson(baselineData);

      final List<WorkoutSet> syntheticSets = [];
      final isManualAdd = plannedWorkout.targetWeight == 0 && plannedWorkout.targetReps == 0;

      if (isManualAdd) {
        syntheticSets.add(WorkoutSet(
          id: const Uuid().v4(),
          baselineId: baseline.id,
          weight: 0.0,
          reps: 0,
          sets: 1,
          isCompleted: false,
          createdAt: date,
        ));
      } else {
        final setCount = plannedWorkout.targetSets > 0 ? plannedWorkout.targetSets : 1;
        for (int i = 0; i < setCount; i++) {
          syntheticSets.add(WorkoutSet(
            id: const Uuid().v4(),
            baselineId: baseline.id,
            weight: plannedWorkout.targetWeight,
            reps: plannedWorkout.targetReps,
            sets: i + 1,
            isCompleted: false,
            createdAt: date,
          ));
        }
      }

      final baselineWithSets = baseline.copyWith(
        workoutSets: syntheticSets,
        isHiddenFromHome: false,
      );

      resultBaselines.add(baselineWithSets);
      plannedWorkoutMap[baseline.id] = plannedWorkout;
    }

    return (resultBaselines, plannedWorkoutMap);
  }

  /// 계획된 운동을 로그로 변환 완료 처리
  Future<void> markPlannedWorkoutAsConverted(String plannedWorkoutId) async {
    final userId = currentUserId;

    await client
        .from('planned_workouts')
        .update({'is_converted_to_log': true})
        .eq('id', plannedWorkoutId)
        .eq('user_id', userId);
  }

  /// 지난 주 운동을 다음 주로 복사 (유지 모드)
  Future<int> duplicatePastWeekToNextWeek(String colorHex) async {
    await ensureProfileExists();
    final userId = currentUserId;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

    final response = await client
        .from('workout_sets')
        .select('''
          id,
          baseline_id,
          weight,
          reps,
          sets,
          created_at,
          exercise_baselines!inner(
            id,
            user_id,
            exercise_name,
            body_part
          )
        ''')
        .eq('exercise_baselines.user_id', userId)
        .gte('created_at', '${startStr}T00:00:00')
        .lte('created_at', '${endStr}T23:59:59')
        .order('created_at', ascending: true);

    if ((response as List).isEmpty) {
      return 0;
    }

    final Map<String, Map<String, dynamic>> workoutsByDateAndExercise = {};

    for (final row in response) {
      final createdAt = DateTime.parse(row['created_at']);
      final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
      final baseline = row['exercise_baselines'];
      final exerciseName = baseline['exercise_name'] as String;
      final baselineId = baseline['id'] as String;
      final weight = (row['weight'] as num).toDouble();
      final reps = row['reps'] as int;

      final key = '$dateKey|$exerciseName';

      if (!workoutsByDateAndExercise.containsKey(key)) {
        workoutsByDateAndExercise[key] = {
          'dateKey': dateKey,
          'exerciseName': exerciseName,
          'baselineId': baselineId,
          'maxWeight': weight,
          'maxReps': reps,
          'totalSets': 1,
        };
      } else {
        final existing = workoutsByDateAndExercise[key]!;
        if (weight > (existing['maxWeight'] as double)) {
          existing['maxWeight'] = weight;
        }
        if (reps > (existing['maxReps'] as int)) {
          existing['maxReps'] = reps;
        }
        existing['totalSets'] = (existing['totalSets'] as int) + 1;
      }
    }

    final plannedWorkouts = <PlannedWorkout>[];
    const uuid = Uuid();

    for (final entry in workoutsByDateAndExercise.values) {
      final originalDate = DateTime.parse(entry['dateKey']);
      final nextWeekDate = originalDate.add(const Duration(days: 7));

      final plannedWorkout = PlannedWorkout(
        id: uuid.v4(),
        userId: userId,
        baselineId: entry['baselineId'],
        scheduledDate: nextWeekDate,
        targetWeight: entry['maxWeight'],
        targetReps: entry['maxReps'],
        targetSets: entry['totalSets'],
        exerciseName: entry['exerciseName'],
        aiComment: '지난주 운동 유지',
        isCompleted: false,
        isConvertedToLog: false,
        colorHex: colorHex,
        createdAt: DateTime.now(),
      );

      plannedWorkouts.add(plannedWorkout);
    }

    if (plannedWorkouts.isNotEmpty) {
      await savePlannedWorkouts(plannedWorkouts);
    }

    return plannedWorkouts.length;
  }
}
