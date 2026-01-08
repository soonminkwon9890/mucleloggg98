import 'dart:io';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import '../models/check_point.dart';
import '../services/supabase_service.dart';
import '../../core/constants/app_constants.dart';

/// 운동 데이터 레포지토리
class WorkoutRepository {
  final _client = SupabaseService.client;
  final _storage = SupabaseService.storageBucket;

  /// 운동 기준 정보 저장
  Future<ExerciseBaseline> saveBaseline(ExerciseBaseline baseline) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final data = baseline.toJson();
    data['user_id'] = userId;

    // DateTime 필드를 ISO 8601 문자열로 변환
    if (data['created_at'] != null && data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    final response =
        await _client.from('exercise_baselines').insert(data).select().single();

    return ExerciseBaseline.fromJson(response);
  }

  /// 사용자의 모든 운동 기준 정보 가져오기 (조인 쿼리 사용)
  Future<List<ExerciseBaseline>> getBaselines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 조인 쿼리: exercise_baselines와 workout_sets를 함께 가져오기
    final response = await _client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();
  }

  /// 특정 운동 기준 정보 가져오기 (조인 쿼리 사용)
  Future<ExerciseBaseline?> getBaselineById(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('id', baselineId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
  }

  /// Baseline의 영상 URL 업데이트
  Future<void> updateBaselineVideo(
    String baselineId,
    String videoUrl,
    String? thumbnailUrl,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final updateData = <String, dynamic>{
      'video_url': videoUrl,
    };

    if (thumbnailUrl != null) {
      updateData['thumbnail_url'] = thumbnailUrl;
    }

    await _client
        .from('exercise_baselines')
        .update(updateData)
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 영상 파일 업로드
  Future<String> uploadVideo(File videoFile, String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${AppConstants.videoExtension}';
    final filePath = '$userId/$baselineId/$fileName';

    await _storage.upload(filePath, videoFile);

    final url = _storage.getPublicUrl(filePath);
    return url;
  }

  /// 썸네일 이미지 업로드
  Future<String> uploadThumbnail(File thumbnailFile, String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${AppConstants.imageExtension}';
    final filePath = '$userId/$baselineId/$fileName';

    await _storage.upload(filePath, thumbnailFile);

    final url = _storage.getPublicUrl(filePath);
    return url;
  }

  /// 운동 세트 기록 저장
  Future<WorkoutSet> saveWorkoutSet(WorkoutSet workoutSet) async {
    final data = workoutSet.toJson();
    data['baseline_id'] = workoutSet.baselineId;

    // DateTime 필드를 ISO 8601 문자열로 변환
    if (data['created_at'] != null && data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    final response =
        await _client.from('workout_sets').insert(data).select().single();

    return WorkoutSet.fromJson(response);
  }

  /// 특정 운동의 모든 세트 기록 가져오기
  Future<List<WorkoutSet>> getWorkoutSets(String baselineId) async {
    final response = await _client
        .from('workout_sets')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// 최근 세트 기록 가져오기
  Future<WorkoutSet?> getLatestWorkoutSet(String baselineId) async {
    final response = await _client
        .from('workout_sets')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return WorkoutSet.fromJson(response);
  }

  /// 중간 점검 데이터 저장
  Future<CheckPoint> saveCheckPoint(CheckPoint checkPoint) async {
    final data = checkPoint.toJson();
    data['baseline_id'] = checkPoint.baselineId;

    // DateTime 필드를 ISO 8601 문자열로 변환
    if (data['created_at'] != null && data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    final response =
        await _client.from('check_points').insert(data).select().single();

    return CheckPoint.fromJson(response);
  }

  /// 특정 운동의 중간 점검 데이터 가져오기
  Future<List<CheckPoint>> getCheckPoints(String baselineId) async {
    final response = await _client
        .from('check_points')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CheckPoint.fromJson(json)).toList();
  }

  /// 사용자의 운동 날짜 목록 가져오기 (달력용)
  Future<List<DateTime>> getWorkoutDates() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // exercise_baselines에서 사용자의 baseline_id 목록 가져오기
    final baselinesResponse = await _client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId);

    if (baselinesResponse.isEmpty) {
      return [];
    }

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    // 각 baseline_id에 대해 개별적으로 쿼리하고 결과 합치기
    final dates = <DateTime>{};
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('workout_sets')
            .select('created_at')
            .eq('baseline_id', baselineId);

        for (final item in response as List) {
          final createdAt = item['created_at'] as String?;
          if (createdAt != null) {
            try {
              final dateTime = DateTime.parse(createdAt);
              // 날짜만 추출 (시간 제거)
              final dateOnly =
                  DateTime(dateTime.year, dateTime.month, dateTime.day);
              dates.add(dateOnly);
            } catch (e) {
              // 파싱 실패 시 무시
              continue;
            }
          }
        }
      } catch (e) {
        // 쿼리 실패 시 무시하고 다음 baseline_id로 진행
        continue;
      }
    }

    return dates.toList()..sort();
  }

  /// 특정 날짜의 운동 기록 가져오기
  /// date의 00:00:00 이상 ~ date+1일의 00:00:00 미만인 데이터 조회
  Future<List<ExerciseBaseline>> getWorkoutsByDate(DateTime date) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 날짜 범위 설정: date의 00:00:00 ~ date+1일의 00:00:00
    final startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endDate = startDate.add(const Duration(days: 1));

    // workout_sets에서 해당 날짜 범위의 세트 조회
    final setsResponse = await _client
        .from('workout_sets')
        .select('baseline_id')
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String());

    if (setsResponse.isEmpty) {
      return [];
    }

    // baseline_id 중복 제거
    final baselineIds = (setsResponse as List)
        .map((json) => json['baseline_id'] as String)
        .toSet()
        .toList();

    if (baselineIds.isEmpty) {
      return [];
    }

    // 각 baseline_id에 대해 조인 쿼리로 데이터 가져오기
    final baselines = <ExerciseBaseline>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('exercise_baselines')
            .select('*, workout_sets(*)')
            .eq('id', baselineId)
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          baselines.add(ExerciseBaseline.fromJson(response));
        }
      } catch (e) {
        // 쿼리 실패 시 무시하고 다음 baseline_id로 진행
        continue;
      }
    }

    return baselines;
  }

  /// 특정 운동의 월별 기록 조회
  /// 운동명으로 모든 세트를 조회하고 월별로 그룹화하여 반환
  Future<Map<String, List<WorkoutSet>>> getWorkoutHistoryByExercise(
      String exerciseName) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // exercise_baselines에서 운동명으로 baseline_id 찾기
    final baselinesResponse = await _client
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

    // 모든 baseline_id에 대한 세트 조회
    final allSets = <WorkoutSet>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('workout_sets')
            .select()
            .eq('baseline_id', baselineId)
            .order('created_at', ascending: false);

        final sets = (response as List)
            .map((json) => WorkoutSet.fromJson(json))
            .toList();
        allSets.addAll(sets);
      } catch (e) {
        // 쿼리 실패 시 무시하고 다음 baseline_id로 진행
        continue;
      }
    }

    // 월별로 그룹화 (yyyy-MM 형식)
    final Map<String, List<WorkoutSet>> groupedByMonth = {};
    for (final set in allSets) {
      if (set.createdAt == null) continue;

      final monthKey =
          '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}';
      groupedByMonth.putIfAbsent(monthKey, () => []).add(set);
    }

    // 각 월별 리스트를 날짜순으로 정렬
    for (final key in groupedByMonth.keys) {
      groupedByMonth[key]!.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    }

    return groupedByMonth;
  }
}
