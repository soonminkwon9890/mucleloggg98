import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import 'base_repository.dart';
import 'workout_set_repository.dart';

/// 루틴(Routine) 레포지토리
///
/// routines, routine_items 테이블 관련 CRUD 작업을 담당합니다.
class RoutineRepository with BaseRepositoryMixin {
  final WorkoutSetRepository _setRepository = WorkoutSetRepository();

  /// 루틴 저장
  Future<Routine> saveRoutine(Routine routine, List<RoutineItem> items) async {
    final userId = currentUserId;
    await ensureProfileExists();

    final routineData = routine.toJson();
    routineData['user_id'] = userId;

    if (routineData['created_at'] != null && routineData['created_at'] is DateTime) {
      routineData['created_at'] = (routineData['created_at'] as DateTime).toIso8601String();
    }

    final routineResponse =
        await client.from('routines').insert(routineData).select().single();

    final savedRoutine = Routine.fromJson(routineResponse);

    for (var item in items) {
      final itemData = item.toJson();
      itemData['routine_id'] = savedRoutine.id;
      if (itemData['created_at'] != null && itemData['created_at'] is DateTime) {
        itemData['created_at'] = (itemData['created_at'] as DateTime).toIso8601String();
      }
      await client.from('routine_items').insert(itemData);
    }

    final result = await getRoutineById(savedRoutine.id);
    return result ?? savedRoutine;
  }

  /// 사용자의 모든 루틴 조회
  Future<List<Routine>> getRoutines() async {
    final userId = currentUserId;

    final response = await client
        .from('routines')
        .select('*, routine_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final routine = Routine.fromJson(json);
      if (routine.routineItems != null && routine.routineItems!.length > 1) {
        final sortedItems = List<RoutineItem>.from(routine.routineItems!)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return routine.copyWith(routineItems: sortedItems);
      }
      return routine;
    }).toList();
  }

  /// 특정 루틴 조회
  Future<Routine?> getRoutineById(String id) async {
    final userId = currentUserId;

    final response = await client
        .from('routines')
        .select('*, routine_items(*)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    final routine = Routine.fromJson(response);
    if (routine.routineItems != null && routine.routineItems!.length > 1) {
      final sortedItems = List<RoutineItem>.from(routine.routineItems!)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return routine.copyWith(routineItems: sortedItems);
    }

    return routine;
  }

  /// 루틴 수정
  Future<Routine> updateRoutine(String id, Routine routine, List<RoutineItem> items) async {
    final userId = currentUserId;

    final routineData = routine.toJson();
    routineData.remove('id');
    routineData.remove('user_id');
    routineData.remove('routine_items');

    await client
        .from('routines')
        .update(routineData)
        .eq('id', id)
        .eq('user_id', userId);

    // 기존 RoutineItem 삭제 후 새로 추가
    await client.from('routine_items').delete().eq('routine_id', id);

    for (var item in items) {
      final itemData = item.toJson();
      itemData['routine_id'] = id;
      if (itemData['created_at'] != null && itemData['created_at'] is DateTime) {
        itemData['created_at'] = (itemData['created_at'] as DateTime).toIso8601String();
      }
      await client.from('routine_items').insert(itemData);
    }

    final result = await getRoutineById(id);
    return result ?? routine;
  }

  /// 루틴 이름만 수정
  Future<void> updateRoutineName(String routineId, String newName) async {
    final userId = currentUserId;

    await client
        .from('routines')
        .update({'name': newName})
        .eq('id', routineId)
        .eq('user_id', userId);
  }

  /// 루틴에서 개별 운동 삭제
  ///
  /// 보안: routine_items 에는 user_id 컬럼이 없으므로 routines 조인으로
  /// 소유권을 검증한 뒤 삭제합니다 (IDOR 방어 - 앱 레이어 2차 방어선).
  Future<void> removeExerciseFromRoutine(String routineItemId) async {
    final ownerCheck = await client
        .from('routine_items')
        .select('id, routines!inner(user_id)')
        .eq('id', routineItemId)
        .eq('routines.user_id', currentUserId)
        .maybeSingle();

    if (ownerCheck == null) {
      throw Exception('루틴 항목을 찾을 수 없거나 삭제 권한이 없습니다.');
    }

    await client.from('routine_items').delete().eq('id', routineItemId);
  }

  /// 루틴 내 운동 순서 변경
  ///
  /// 보안: routineId 가 현재 사용자 소유인지 먼저 검증합니다 (IDOR 방어).
  Future<void> updateRoutineItemOrder(String routineId, List<String> newOrder) async {
    final ownerCheck = await client
        .from('routines')
        .select('id')
        .eq('id', routineId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (ownerCheck == null) {
      throw Exception('루틴을 찾을 수 없거나 수정 권한이 없습니다.');
    }

    for (int i = 0; i < newOrder.length; i++) {
      await client
          .from('routine_items')
          .update({'sort_order': i})
          .eq('id', newOrder[i])
          .eq('routine_id', routineId);
    }
  }

  /// 루틴 삭제
  Future<void> deleteRoutine(String routineId) async {
    try {
      // 1. exercise_baselines의 routine_id를 null로 업데이트
      await client
          .from('exercise_baselines')
          .update({'routine_id': null}).eq('routine_id', routineId);

      // 2. routine_items 삭제
      await client.from('routine_items').delete().eq('routine_id', routineId);

      // 3. routines 삭제
      await client.from('routines').delete().eq('id', routineId);
    } catch (e) {
      throw Exception('루틴 삭제 실패: $e');
    }
  }

  /// 루틴에 운동 추가
  Future<void> addExercisesToRoutine(
    String routineId,
    List<String> baselineIds,
    Future<List<ExerciseBaseline>> Function() getBaselines,
  ) async {
    await ensureProfileExists();

    // 기존 routine_items의 sort_order 최댓값 조회
    final existingItemsResponse = await client
        .from('routine_items')
        .select('sort_order')
        .eq('routine_id', routineId)
        .order('sort_order', ascending: false)
        .limit(1);

    int startSortOrder = 0;
    if (existingItemsResponse.isNotEmpty) {
      final maxSortOrder = existingItemsResponse[0]['sort_order'] as int? ?? 0;
      startSortOrder = maxSortOrder + 1;
    }

    final baselines = await getBaselines();
    final selectedBaselines = baselines.where((b) => baselineIds.contains(b.id)).toList();

    for (int i = 0; i < selectedBaselines.length; i++) {
      final baseline = selectedBaselines[i];
      final item = RoutineItem(
        id: const Uuid().v4(),
        routineId: routineId,
        exerciseName: baseline.exerciseName,
        bodyPart: baseline.bodyPart,
        sortOrder: startSortOrder + i,
        createdAt: DateTime.now(),
      );

      final itemData = item.toJson();
      itemData['routine_id'] = routineId;
      if (itemData['created_at'] != null && itemData['created_at'] is DateTime) {
        itemData['created_at'] = (itemData['created_at'] as DateTime).toIso8601String();
      }

      await client.from('routine_items').insert(itemData);
    }
  }

  /// 특정 운동이 포함된 루틴 조회
  Future<List<Routine>> getRoutinesByExerciseName(String exerciseName) async {
    final itemsResponse = await client
        .from('routine_items')
        .select('routine_id')
        .eq('exercise_name', exerciseName);

    if (itemsResponse.isEmpty) return [];

    final routineIds = (itemsResponse as List)
        .map((item) => item['routine_id'] as String)
        .toSet()
        .toList();

    final routines = <Routine>[];
    for (final routineId in routineIds) {
      final routine = await getRoutineById(routineId);
      if (routine != null) {
        routines.add(routine);
      }
    }

    return routines;
  }

  /// 루틴 실행 이력 조회
  Future<Map<String, List<ExerciseBaseline>>> getRoutineExecutionHistory(String routineId) async {
    final userId = currentUserId;

    final response = await client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('routine_id', routineId)
        .order('created_at', ascending: false);

    final baselines = (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();

    final Map<String, List<ExerciseBaseline>> grouped = {};
    for (final baseline in baselines) {
      if (baseline.createdAt == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(baseline.createdAt!);
      grouped.putIfAbsent(dateKey, () => []).add(baseline);
    }

    return grouped;
  }

  /// 홈 화면 운동들을 루틴으로 일괄 저장
  Future<void> saveRoutineFromWorkouts(
    String routineName,
    List<ExerciseBaseline> baselines,
  ) async {
    final userId = currentUserId;
    await ensureProfileExists();

    // 1. 모든 운동의 세트를 is_completed = true로 저장
    final allSetsToSave = <WorkoutSet>[];
    for (final baseline in baselines) {
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        continue;
      }

      for (final set in baseline.workoutSets!) {
        final completedSet = set.copyWith(isCompleted: true);
        allSetsToSave.add(completedSet);
      }
    }

    if (allSetsToSave.isNotEmpty) {
      await _setRepository.batchSaveWorkoutSets(allSetsToSave);
    }

    // 2. 루틴 생성
    final routine = Routine(
      id: const Uuid().v4(),
      userId: userId,
      name: routineName,
      createdAt: DateTime.now(),
    );

    final routineData = routine.toJson();
    if (routineData['created_at'] != null && routineData['created_at'] is DateTime) {
      routineData['created_at'] = (routineData['created_at'] as DateTime).toIso8601String();
    }

    await client.from('routines').insert(routineData);

    // 3. RoutineItem 생성 및 저장
    final itemsData = <Map<String, dynamic>>[];
    for (int i = 0; i < baselines.length; i++) {
      final baseline = baselines[i];
      final item = RoutineItem(
        id: const Uuid().v4(),
        routineId: routine.id,
        exerciseName: baseline.exerciseName,
        bodyPart: baseline.bodyPart,
        sortOrder: i,
        createdAt: DateTime.now(),
      );

      final itemData = item.toJson();
      itemData['routine_id'] = routine.id;
      if (itemData['created_at'] != null && itemData['created_at'] is DateTime) {
        itemData['created_at'] = (itemData['created_at'] as DateTime).toIso8601String();
      }

      itemsData.add(itemData);
    }

    if (itemsData.isNotEmpty) {
      await client.from('routine_items').insert(itemsData);
    }

    // 4. exercise_baselines의 routine_id 업데이트
    final baselineIds = baselines.map((b) => b.id).toList();
    if (baselineIds.isNotEmpty) {
      for (final baselineId in baselineIds) {
        await client
            .from('exercise_baselines')
            .update({'routine_id': routine.id})
            .eq('id', baselineId)
            .eq('user_id', userId);
      }
    }
  }
}
