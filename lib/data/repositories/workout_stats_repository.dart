import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import '../models/workout_session.dart';
import '../models/exercise_with_history.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/enums/exercise_enums.dart';
import 'base_repository.dart';

/// 운동 통계/분석 레포지토리
///
/// 운동 기록 조회, 통계, 분석 관련 읽기 전용 작업을 담당합니다.
class WorkoutStatsRepository with BaseRepositoryMixin {
  /// 사용자의 운동 날짜 목록 가져오기 (달력용)
  Future<List<DateTime>> getWorkoutDates() async {
    final userId = currentUserId;

    final baselinesResponse = await client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId);

    if (baselinesResponse.isEmpty) {
      return [];
    }

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    final dates = <DateTime>{};
    for (final baselineId in baselineIds) {
      try {
        final response = await client
            .from('workout_sets')
            .select('created_at')
            .eq('baseline_id', baselineId)
            .eq('is_completed', true);

        for (final item in response as List) {
          final createdAt = item['created_at'] as String?;
          if (createdAt != null) {
            try {
              final localDateTime = DateTime.parse(createdAt).toLocal();
              final dateOnly = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
              dates.add(dateOnly);
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return dates.toList()..sort();
  }

  /// 특정 날짜의 운동 기록 가져오기
  Future<List<ExerciseBaseline>> getWorkoutsByDate(
    DateTime date, {
    bool completedOnly = false,
  }) async {
    final userId = currentUserId;

    // 엄격한 UTC 경계: 로컬 자정(00:00:00) ~ 로컬 23:59:59.999 를 UTC 로 변환하여
    // 인접 날짜 간 경계 겹침(KST +9h 오프셋에서 ±2일 버퍼를 쓸 때 발생하는 ghost) 을 차단합니다.
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0).toUtc();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toUtc();

    var query = client
        .from('workout_sets')
        .select(
          'id, baseline_id, weight, reps, sets, rpe, rpe_level, estimated_1rm, is_ai_suggested, performance_score, is_completed, is_hidden, created_at, exercise_baselines!inner(user_id)',
        )
        .gte('created_at', startOfDay.toIso8601String())
        .lte('created_at', endOfDay.toIso8601String())
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId);

    if (completedOnly) {
      query = query.eq('is_completed', true);
    }

    final setsResponse = await query.order('created_at', ascending: true);

    if (setsResponse.isEmpty) {
      return [];
    }

    final Map<String, List<WorkoutSet>> dailySetsByBaselineId = {};
    for (final row in (setsResponse as List)) {
      if (row is! Map<String, dynamic>) continue;

      final createdAtStr = row['created_at'] as String?;
      if (createdAtStr == null) continue;

      final rowMap = Map<String, dynamic>.from(row);
      rowMap.remove('exercise_baselines');

      final set = WorkoutSet.fromJson(rowMap);
      dailySetsByBaselineId.putIfAbsent(set.baselineId, () => []).add(set);
    }

    if (dailySetsByBaselineId.isEmpty) {
      return [];
    }

    final baselineIds = dailySetsByBaselineId.keys.toList();

    final baselinesResponse = await client
        .from('exercise_baselines')
        .select()
        .eq('user_id', userId)
        .inFilter('id', baselineIds);

    final baselines = (baselinesResponse as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();

    final merged = baselines.map((baseline) {
      final sets = List<WorkoutSet>.from(dailySetsByBaselineId[baseline.id] ?? []);
      sets.sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
      return baseline.copyWith(workoutSets: sets);
    }).toList();

    return merged;
  }

  /// 오늘 날짜의 운동 기준 정보 가져오기
  Future<List<ExerciseBaseline>> getTodayBaselines() async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return await getWorkoutsByDate(normalizedToday);
  }


  /// 특정 운동의 날짜별 기록 조회
  Future<Map<String, List<WorkoutSet>>> getHistoryByExerciseName(String exerciseName) async {
    final userId = currentUserId;

    final baselinesResponse = await client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (baselinesResponse.isEmpty) {
      return {};
    }

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    final allSets = <WorkoutSet>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await client
            .from('workout_sets')
            .select()
            .eq('baseline_id', baselineId)
            .eq('is_completed', true)
            .eq('is_hidden', false)
            .order('created_at', ascending: false);

        final sets = (response as List)
            .map((json) => WorkoutSet.fromJson(json))
            .toList();
        allSets.addAll(sets);
      } catch (e) {
        continue;
      }
    }

    final Map<String, List<WorkoutSet>> groupedByDate = {};
    for (final set in allSets) {
      if (set.createdAt == null) continue;

      final localCreatedAt = set.createdAt!.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(localCreatedAt);
      groupedByDate.putIfAbsent(dateKey, () => []).add(set);
    }

    for (final key in groupedByDate.keys) {
      groupedByDate[key]!.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    }

    return groupedByDate;
  }

  /// 특정 주(월~일) 주간 볼륨 조회
  Future<Map<DateTime, double>> getWeeklyVolume({DateTime? weekStart}) async {
    final userId = currentUserId;

    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final rawStart = weekStart ?? todayLocal.subtract(Duration(days: now.weekday - 1));
    final effectiveWeekStart = DateTime(rawStart.year, rawStart.month, rawStart.day);

    final endOfWeek = effectiveWeekStart.add(const Duration(days: 6));

    final queryStart = effectiveWeekStart.subtract(const Duration(days: 1));
    final queryEnd = endOfWeek.add(const Duration(days: 1));

    final startUtc = queryStart.toUtc().toIso8601String();
    final endUtc = queryEnd.toUtc().toIso8601String();

    final response = await client
        .from('workout_sets')
        .select('baseline_id, created_at, weight, reps, exercise_baselines!inner(user_id)')
        .eq('is_completed', true)
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId)
        .gte('created_at', startUtc)
        .lt('created_at', endUtc);

    final result = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      final d = effectiveWeekStart.add(Duration(days: i));
      result[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (final row in (response as List)) {
      if (row is! Map) continue;
      final createdAtRaw = row['created_at'];
      if (createdAtRaw == null) continue;

      final createdAtLocal = DateTime.parse(createdAtRaw.toString()).toLocal();
      final dayKey = DateTime(createdAtLocal.year, createdAtLocal.month, createdAtLocal.day);

      if (!result.containsKey(dayKey)) continue;

      final weight = (row['weight'] as num?)?.toDouble() ?? 0.0;
      final reps = (row['reps'] as num?)?.toInt() ?? 0;
      final volume = weight * reps;

      result[dayKey] = (result[dayKey] ?? 0.0) + volume;
    }

    return result;
  }

  /// 특정 주(월~일) 부위 밸런스 집계
  Future<Map<String, double>> getBodyBalance({DateTime? weekStart}) async {
    final userId = currentUserId;

    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final rawStart = weekStart ?? todayLocal.subtract(Duration(days: now.weekday - 1));
    final effectiveWeekStart = DateTime(rawStart.year, rawStart.month, rawStart.day);

    final weekEnd = effectiveWeekStart.add(const Duration(days: 6));

    final queryStart = effectiveWeekStart.subtract(const Duration(days: 1));
    final queryEnd = weekEnd.add(const Duration(days: 1));

    final startUtc = queryStart.toUtc().toIso8601String();
    final endUtc = queryEnd.toUtc().toIso8601String();

    final response = await client
        .from('workout_sets')
        .select('baseline_id, created_at, exercise_baselines!inner(user_id, body_part, target_muscles)')
        .eq('is_completed', true)
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId)
        .gte('created_at', startUtc)
        .lt('created_at', endUtc);

    const axes = ['가슴', '등', '어깨', '이두', '삼두', '코어', '대퇴사두', '햄스트링', '둔근', '종아리'];
    final result = {for (final a in axes) a: 0.0};

    final seen = <String>{};

    for (final row in (response as List)) {
      if (row is! Map) continue;
      final baselineId = row['baseline_id']?.toString();
      final createdAtRaw = row['created_at']?.toString();
      if (baselineId == null || createdAtRaw == null) continue;

      final createdAt = DateTime.parse(createdAtRaw).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);

      final dayKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final weekStartNormalized = DateTime(
        effectiveWeekStart.year,
        effectiveWeekStart.month,
        effectiveWeekStart.day,
      );
      final weekEndNormalized = DateTime(
        weekEnd.year,
        weekEnd.month,
        weekEnd.day,
      );

      if (dayKey.isBefore(weekStartNormalized) || dayKey.isAfter(weekEndNormalized)) {
        continue;
      }

      final dedupeKey = '$dateKey|$baselineId';
      if (!seen.add(dedupeKey)) continue;

      final baselineRow = _extractEmbeddedBaseline(row['exercise_baselines']);
      if (baselineRow == null) continue;

      final bodyPartCode = baselineRow['body_part']?.toString();
      final bodyPart = BodyPartParsing.fromCode(bodyPartCode);

      if (bodyPart == BodyPart.full) {
        for (final a in axes) {
          result[a] = (result[a] ?? 0.0) + 0.2;
        }
        continue;
      }

      final muscles = _extractTargetMuscles(baselineRow['target_muscles']);
      final mappedAxes = <String>{};
      for (final m in muscles) {
        for (final axis in mapMuscleToAxes(m)) {
          if (axis != '기타') mappedAxes.add(axis);
        }
      }

      if (mappedAxes.isEmpty) continue;

      final per = 1.0 / mappedAxes.length;
      for (final a in mappedAxes) {
        result[a] = (result[a] ?? 0.0) + per;
      }
    }

    return result;
  }

  Map<String, dynamic>? _extractEmbeddedBaseline(dynamic embedded) {
    if (embedded is Map) {
      return Map<String, dynamic>.from(embedded);
    }
    if (embedded is List && embedded.isNotEmpty && embedded.first is Map) {
      return Map<String, dynamic>.from(embedded.first);
    }
    return null;
  }

  List<String> _extractTargetMuscles(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// 근육 문자열 → 차트 축 이름 목록 (레거시 '팔'은 ['이두','삼두'] 모두 반환)
  List<String> mapMuscleToAxes(String muscle) {
    final m = muscle.trim();
    if (m.isEmpty) return const ['기타'];

    if (m.contains('가슴') || m.contains('흉') || m.contains('대흉')) return const ['가슴'];
    if (m.contains('등') || m.contains('광배') || m.contains('승모')) return const ['등'];
    if (m.contains('어깨') || m.contains('삼각')) return const ['어깨'];
    if (m.contains('이두') || m.contains('전완')) return const ['이두'];
    if (m.contains('삼두')) return const ['삼두'];
    // 레거시 '팔' → 이두 + 삼두 양쪽 모두 집계
    if (m.contains('팔')) return const ['이두', '삼두'];
    // 레거시 '복근' 포함 → 코어
    if (m.contains('코어') || m.contains('복근') || m.contains('복직')) return const ['코어'];
    if (m.contains('대퇴') || m.contains('사두') || m.contains('쿼드')) return const ['대퇴사두'];
    if (m.contains('햄') || m.contains('햄스트링')) return const ['햄스트링'];
    if (m.contains('둔근') || m.contains('엉덩')) return const ['둔근'];
    if (m.contains('종아리') || m.contains('비복') || m.contains('가자미')) return const ['종아리'];

    return const ['기타'];
  }

  /// 단일 축 반환 (하위 호환용 — 복수 매핑 시 첫 번째 값 반환)
  String mapMuscleToAxis(String muscle) => mapMuscleToAxes(muscle).first;

  /// 특정 운동의 날짜별 강도 조회
  Future<Map<String, String?>> getDifficultyByExerciseName(String exerciseName) async {
    final userId = currentUserId;

    final baselinesResponse = await client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (baselinesResponse.isEmpty) return {};

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    final Map<String, String?> difficultyMap = {};

    for (final baselineId in baselineIds) {
      try {
        final response = await client
            .from('workout_sessions')
            .select('workout_date, difficulty')
            .eq('baseline_id', baselineId)
            .not('difficulty', 'is', null)
            .order('workout_date', ascending: false);

        for (final row in response as List) {
          final workoutDate = row['workout_date'];
          final difficulty = row['difficulty'] as String?;

          if (workoutDate != null && difficulty != null) {
            final date = workoutDate is String
                ? DateTime.parse(workoutDate)
                : DateTime.parse(workoutDate.toString());
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            difficultyMap.putIfAbsent(dateKey, () => difficulty);
          }
        }
      } catch (e) {
        continue;
      }
    }

    return difficultyMap;
  }

  /// 특정 운동의 월별 기록 조회
  Future<Map<String, List<WorkoutSet>>> getWorkoutHistoryByExercise(String exerciseName) async {
    final userId = currentUserId;

    final baselinesResponse = await client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (baselinesResponse.isEmpty) {
      return {};
    }

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    final allSets = <WorkoutSet>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await client
            .from('workout_sets')
            .select()
            .eq('baseline_id', baselineId)
            .order('created_at', ascending: false);

        final sets = (response as List)
            .map((json) => WorkoutSet.fromJson(json))
            .toList();
        allSets.addAll(sets);
      } catch (e) {
        continue;
      }
    }

    final Map<String, List<WorkoutSet>> groupedByMonth = {};
    for (final set in allSets) {
      if (set.createdAt == null) continue;

      final monthKey = '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}';
      groupedByMonth.putIfAbsent(monthKey, () => []).add(set);
    }

    for (final key in groupedByMonth.keys) {
      groupedByMonth[key]!.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    }

    return groupedByMonth;
  }

  /// 완료된 운동 기록이 있는 운동 목록 + 수행 날짜 리스트 조회
  Future<List<ExerciseWithHistory>> getExercisesWithHistory() async {
    final userId = currentUserId;

    final response = await client
        .from('workout_sets')
        .select('baseline_id, created_at, exercise_baselines!inner(exercise_name, user_id)')
        .eq('is_completed', true)
        .eq('exercise_baselines.user_id', userId);

    if (response.isEmpty) return [];

    final Map<String, ({String exerciseName, Set<DateTime> dates})> grouped = {};

    for (final row in (response as List)) {
      if (row is! Map<String, dynamic>) continue;

      final baselineId = row['baseline_id'] as String?;
      final createdAtRaw = row['created_at'];
      final joined = row['exercise_baselines'];

      if (baselineId == null || baselineId.isEmpty || createdAtRaw == null) {
        continue;
      }

      String? exerciseName;
      if (joined is List && joined.isNotEmpty) {
        final first = joined.first;
        if (first is Map) {
          exerciseName = first['exercise_name'] as String?;
        }
      } else if (joined is Map) {
        exerciseName = joined['exercise_name'] as String?;
      }

      if (exerciseName == null || exerciseName.trim().isEmpty) continue;

      final createdAt = DateTime.parse(createdAtRaw.toString()).toLocal();
      final dateOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);

      final existing = grouped[baselineId];
      if (existing == null) {
        grouped[baselineId] = (exerciseName: exerciseName.trim(), dates: {dateOnly});
      } else {
        existing.dates.add(dateOnly);
      }
    }

    final result = grouped.entries
        .map((e) => ExerciseWithHistory(
              baselineId: e.key,
              exerciseName: e.value.exerciseName,
              performedDates: e.value.dates.toList(),
            ))
        .toList()
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

    return result;
  }

  /// 특정 운동의 수행 일수 조회
  Future<int> getExerciseFrequency(String baselineId) async {
    final response = await client
        .from('workout_sets')
        .select('created_at')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true);

    final dates = (response as List).map((item) {
      final createdAt = DateTime.parse(item['created_at']);
      return DateFormat('yyyy-MM-dd').format(createdAt);
    }).toSet();

    return dates.length;
  }

  /// 운동 세션 정보 저장
  Future<void> saveWorkoutSession({
    required String baselineId,
    required DateTime date,
    required String difficulty,
    double? totalVolume,
    int? durationMinutes,
  }) async {
    await ensureProfileExists();
    final userId = currentUserId;

    await client.from('workout_sessions').insert({
      'user_id': userId,
      'baseline_id': baselineId,
      'workout_date': DateFormat('yyyy-MM-dd').format(date),
      'difficulty': difficulty,
      'total_volume': totalVolume,
      'duration_minutes': durationMinutes,
    });
  }

  /// AI 분석용 소스 데이터 조회
  ///
  /// [isNextWeek] == true  → 다음주 루틴 분석: 소스 = 이번 주 (Mon–Sun)
  /// [isNextWeek] == false → 이번주 루틴 분석: 소스 = 지난 주 (prev Mon–prev Sun)
  Future<List<WorkoutSession>> getLastWeekSessions({
    bool isNextWeek = true,
  }) async {
    final userId = currentUserId;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 이번 주 월요일
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    // 소스 주간 시작: isNextWeek=true → 이번 주 월요일, false → 지난 주 월요일
    final startOfWeek =
        isNextWeek ? thisMonday : thisMonday.subtract(const Duration(days: 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final endDate = DateFormat('yyyy-MM-dd').format(endOfWeek);

    debugPrint('[getLastWeekSessions] Query range: $startDate to $endDate');

    final response = await client
        .from('workout_sessions')
        .select('*')
        .eq('user_id', userId)
        .gte('workout_date', startDate)
        .lte('workout_date', endDate)
        .order('workout_date', ascending: false);

    debugPrint('[getLastWeekSessions] Raw response count: ${(response as List).length}');
    for (final row in response) {
      debugPrint('[getLastWeekSessions] Raw row: workout_date=${row['workout_date']}, baseline_id=${row['baseline_id']}');
    }

    final sessions = response
        .map((json) => WorkoutSession.fromJson(json))
        .toList();

    for (final s in sessions) {
      debugPrint('[getLastWeekSessions] Parsed session: workoutDate=${s.workoutDate}, isUtc=${s.workoutDate.isUtc}');
    }

    return sessions;
  }

  /// 특정 날짜의 평균 무게/횟수 조회
  ///
  /// [FIX] UTC 변환 제거 - 로컬 날짜 문자열로 직접 쿼리하여 타임존 이슈 방지
  Future<(double weight, int reps)> getLastWeekAverageSets(
    String baselineId,
    DateTime date,
  ) async {
    // [FIX] UTC 변환 없이 로컬 날짜 문자열 사용
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00';
    final endStr = '${dateStr}T23:59:59.999';

    final response = await client
        .from('workout_sets')
        .select('weight, reps')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    if ((response as List).isEmpty) {
      return (0.0, 0);
    }

    double totalWeight = 0.0;
    int totalReps = 0;
    int count = 0;

    for (final row in response) {
      final weight = (row['weight'] as num?)?.toDouble() ?? 0.0;
      final reps = (row['reps'] as num?)?.toInt() ?? 0;
      totalWeight += weight;
      totalReps += reps;
      count++;
    }

    if (count == 0) return (0.0, 0);
    return (totalWeight / count, (totalReps / count).round());
  }

  /// 특정 날짜의 '최고 중량 세트' 조회
  ///
  /// [FIX] UTC 변환 제거 - 로컬 날짜 문자열로 직접 쿼리하여 타임존 이슈 방지
  Future<(double weight, int reps)> getLastWeekBestSet(
    String baselineId,
    DateTime date,
  ) async {
    // [FIX] UTC 변환 없이 로컬 날짜 문자열 사용
    // created_at은 'YYYY-MM-DDTHH:MM:SS' 형식으로 저장되므로 문자열 범위 쿼리 사용
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00';
    final endStr = '${dateStr}T23:59:59.999';

    debugPrint('[getLastWeekBestSet] Input: baselineId=$baselineId, date=$date');
    debugPrint('[getLastWeekBestSet] Query range (local): $startStr to $endStr');

    final response = await client
        .from('workout_sets')
        .select('weight, reps')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true)
        .gte('created_at', startStr)
        .lte('created_at', endStr)
        .order('weight', ascending: false)
        .limit(1)
        .maybeSingle();

    debugPrint('[getLastWeekBestSet] Response: $response');

    if (response == null) return (0.0, 0);

    final weight = (response['weight'] as num).toDouble();
    final reps = (response['reps'] as num).toInt();
    return (weight, reps);
  }

  /// 사용자 운동 목표 조회
  Future<String> getUserGoal() async {
    final userId = currentUserId;

    try {
      final response = await client
          .from('profiles')
          .select('workout_goal')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 'hypertrophy';

      final goal = response['workout_goal'] as String?;
      return goal ?? 'hypertrophy';
    } catch (e) {
      return 'hypertrophy';
    }
  }

  /// 날짜 변경 시 홈 화면 초기화
  Future<void> resetHomeForNewDay() async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    final today = DateTime.now();

    final response = await client
        .from('exercise_baselines')
        .select('id, workout_sets(*)')
        .eq('user_id', userId)
        .eq('is_hidden_from_home', false);

    for (final baseline in response as List) {
      final workoutSets = baseline['workout_sets'] as List?;
      if (workoutSets == null || workoutSets.isEmpty) continue;

      final hasTodaySets = workoutSets.any((set) {
        if (set['created_at'] == null) return false;
        final createdAt = DateTime.parse(set['created_at']);
        return DateFormatter.isSameDate(createdAt, today);
      });

      if (!hasTodaySets) {
        await client
            .from('exercise_baselines')
            .update({'is_hidden_from_home': true}).eq('id', baseline['id']);
      }
    }
  }
}
