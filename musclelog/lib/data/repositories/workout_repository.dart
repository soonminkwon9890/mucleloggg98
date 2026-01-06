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

    final response =
        await _client.from('exercise_baselines').insert(data).select().single();

    return ExerciseBaseline.fromJson(response);
  }

  /// 사용자의 모든 운동 기준 정보 가져오기
  Future<List<ExerciseBaseline>> getBaselines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('exercise_baselines')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();
  }

  /// 특정 운동 기준 정보 가져오기
  Future<ExerciseBaseline?> getBaselineById(String id) async {
    final response = await _client
        .from('exercise_baselines')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
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
}
