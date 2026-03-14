import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/workout_set.dart';
import '../models/check_point.dart';
import 'base_repository.dart';

/// 운동 세트(WorkoutSet) 레포지토리
///
/// workout_sets 테이블 관련 CRUD 작업을 담당합니다.
class WorkoutSetRepository with BaseRepositoryMixin {
  /// WorkoutSet Upsert (Insert or Update) - 통합 메서드
  Future<WorkoutSet> upsertWorkoutSet(WorkoutSet set) async {
    await ensureProfileExists();

    final data = set.toJson();
    data['baseline_id'] = set.baselineId;
    data['is_completed'] = set.isCompleted;

    // created_at 타임존 처리
    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (data['created_at'] is String) {
      final parsed = DateTime.tryParse(data['created_at'] as String);
      if (parsed != null && !parsed.isUtc) {
        data['created_at'] = parsed.toUtc().toIso8601String();
      }
    } else if (data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toUtc().toIso8601String();
    }

    final response =
        await client.from('workout_sets').upsert(data).select().single();

    return WorkoutSet.fromJson(response);
  }

  /// 세트 일괄 저장 (Batch Insert/Update)
  Future<void> batchSaveWorkoutSets(List<WorkoutSet> sets) async {
    if (sets.isEmpty) return;
    await ensureProfileExists();

    final dataList = sets.map((s) {
      final json = s.toJson();

      if (json['created_at'] == null) {
        json['created_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (json['created_at'] is String) {
        final parsed = DateTime.tryParse(json['created_at'] as String);
        if (parsed != null && !parsed.isUtc) {
          json['created_at'] = parsed.toUtc().toIso8601String();
        }
      } else if (json['created_at'] is DateTime) {
        json['created_at'] = (json['created_at'] as DateTime).toUtc().toIso8601String();
      }

      json['baseline_id'] = s.baselineId;
      json['is_completed'] = s.isCompleted;
      return json;
    }).toList();

    await client.from('workout_sets').upsert(dataList);
  }

  /// 특정 운동의 모든 세트 기록 가져오기
  Future<List<WorkoutSet>> getWorkoutSets(String baselineId) async {
    final response = await client
        .from('workout_sets')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// 최근 세트 기록 가져오기
  Future<WorkoutSet?> getLatestWorkoutSet(String baselineId) async {
    final response = await client
        .from('workout_sets')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return WorkoutSet.fromJson(response);
  }

  /// 오늘 날짜의 특정 운동 세트 기록 조회
  Future<List<WorkoutSet>> getTodayWorkoutSets(String baselineId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final response = await client
        .from('workout_sets')
        .select('*')
        .eq('baseline_id', baselineId)
        .eq('is_hidden', false)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String())
        .order('created_at', ascending: true);

    return (response as List).map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// 세트 삭제
  Future<void> deleteWorkoutSet(String setId) async {
    await client.from('workout_sets').delete().eq('id', setId);
  }

  /// 오늘의 운동 세션 삭제: 오늘 세트 물리 삭제
  Future<void> deleteTodaySets(String baselineId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    await client
        .from('workout_sets')
        .delete()
        .eq('baseline_id', baselineId)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String());
  }

  /// 특정 날짜의 세트 기록 삭제 (Soft Delete)
  Future<void> deleteWorkoutSetsByDate(String baselineId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    // Soft Delete: is_hidden = true
    await client
        .from('workout_sets')
        .update({'is_hidden': true})
        .eq('baseline_id', baselineId)
        .gte('created_at', startStr)
        .lte('created_at', endStr);
  }

  /// 운동 추가/복구 로직 (같은 날짜에 숨겨진 세트 복구)
  Future<bool> recoverOrAddExercise(String baselineId, String userId) async {
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

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    // 숨겨진 세트 조회
    final hiddenSets = await client
        .from('workout_sets')
        .select('id')
        .eq('baseline_id', baselineId)
        .eq('is_hidden', true)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    if ((hiddenSets as List).isNotEmpty) {
      // 숨겨진 세트 복구
      await client
          .from('workout_sets')
          .update({'is_hidden': false})
          .eq('baseline_id', baselineId)
          .eq('is_hidden', true)
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      // exercise_baselines도 표시
      await client
          .from('exercise_baselines')
          .update({
            'is_hidden_from_home': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', baselineId)
          .eq('user_id', userId);

      return true; // 복구됨
    }

    return false; // 신규
  }

  /// 과거 날짜의 세트 데이터를 오늘 날짜로 복사
  Future<void> copySetsToToday(String baselineId, List<WorkoutSet> pastSets, String userId) async {
    await ensureProfileExists();

    // 오늘의 미완료 세트 삭제 (중복 방지)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc();
    final todayEnd = todayStart.add(const Duration(days: 1));

    await client
        .from('workout_sets')
        .delete()
        .eq('baseline_id', baselineId)
        .eq('is_completed', false)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String());

    // 새로운 세트 생성
    final sortedSets = List<WorkoutSet>.from(pastSets);
    sortedSets.sort((a, b) {
      final setsComparison = a.sets.compareTo(b.sets);
      if (setsComparison != 0) return setsComparison;
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      return 0;
    });

    final todayUtc = DateTime.now().toUtc();

    final newSets = <WorkoutSet>[];
    for (int i = 0; i < sortedSets.length; i++) {
      final pastSet = sortedSets[i];
      final newSet = pastSet.copyWith(
        id: const Uuid().v4(),
        baselineId: baselineId,
        sets: i + 1,
        isCompleted: false,
        createdAt: todayUtc,
      );
      newSets.add(newSet);
    }

    if (newSets.isNotEmpty) {
      await batchSaveWorkoutSets(newSets);
    }

    // ExerciseBaseline 상태 업데이트
    await client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 중간 점검 데이터 저장
  Future<CheckPoint> saveCheckPoint(CheckPoint checkPoint) async {
    await ensureProfileExists();

    final data = checkPoint.toJson();
    data['baseline_id'] = checkPoint.baselineId;

    if (data['created_at'] != null && data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    final response =
        await client.from('check_points').insert(data).select().single();

    return CheckPoint.fromJson(response);
  }

  /// 특정 운동의 중간 점검 데이터 가져오기
  Future<List<CheckPoint>> getCheckPoints(String baselineId) async {
    final response = await client
        .from('check_points')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CheckPoint.fromJson(json)).toList();
  }
}
