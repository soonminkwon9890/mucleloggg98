import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/exercise_baseline.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/exercise_enums.dart';
import 'base_repository.dart';

/// 운동 기준 정보(Baseline) 레포지토리
///
/// exercise_baselines 테이블 관련 CRUD 작업을 담당합니다.
class ExerciseRepository with BaseRepositoryMixin {
  /// 운동 기준 정보 저장/수정 통합 (Upsert)
  /// ID 존재 여부에 따라 자동으로 Insert/Update 처리
  Future<ExerciseBaseline> upsertBaseline(ExerciseBaseline baseline) async {
    await ensureProfileExists();
    final userId = currentUserId;

    final data = baseline.toJson();
    data['user_id'] = userId;

    // [중요] 수정(Update) 상황이라도 created_at이 null이 되지 않도록 주의
    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toIso8601String();
    } else if (data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    // updated_at은 항상 현재 시간으로 갱신
    data['updated_at'] = DateTime.now().toIso8601String();

    // 관계형 데이터 제거 (DB 저장 시 불필요)
    data.remove('workout_sets');

    final response =
        await client.from('exercise_baselines').upsert(data).select().single();

    return ExerciseBaseline.fromJson(response);
  }

  /// 사용자의 모든 운동 기준 정보 가져오기 (조인 쿼리 사용)
  /// [수정] 숨김 처리된 운동 제외 + 성능 최적화 (최신 100개만 조회)
  Future<List<ExerciseBaseline>> getBaselines() async {
    final userId = currentUserId;

    final response = await client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('is_hidden_from_home', false)
        .order('updated_at', ascending: false)
        .limit(100);

    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();
  }

  /// 보관함용 운동 목록 조회 (완료된 세트가 있는 운동만 반환)
  Future<List<ExerciseBaseline>> getArchivedBaselines() async {
    final userId = currentUserId;

    final response = await client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .where((baseline) {
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        return false;
      }
      return baseline.workoutSets!.any((set) => set.isCompleted == true);
    }).toList();
  }

  /// 특정 운동 기준 정보 가져오기 (조인 쿼리 사용)
  Future<ExerciseBaseline?> getBaselineById(String baselineId) async {
    final userId = currentUserId;

    final response = await client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('id', baselineId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
  }

  /// 같은 이름/부위/타입의 운동이 있는지 확인
  Future<ExerciseBaseline?> findDuplicateBaseline({
    required String exerciseName,
    required String? bodyPart,
  }) async {
    final userId = currentUserId;

    var query = client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (bodyPart != null) {
      query = query.eq('body_part', bodyPart);
    } else {
      query = query.isFilter('body_part', null);
    }

    final response = await query.maybeSingle();
    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
  }

  /// 운동 추가/활성화 통합 메서드 (신규 생성 및 기존 복구)
  Future<ExerciseBaseline> ensureExerciseVisible(
    String name,
    String bodyPartCode,
    List<String> targetMuscles, {
    Future<bool> Function(String baselineId)? recoverCallback,
  }) async {
    final userId = currentUserId;
    await ensureProfileExists();

    final trimmedName = name.trim();

    final existingBaseline = await client
        .from('exercise_baselines')
        .select('*')
        .eq('user_id', userId)
        .ilike('exercise_name', trimmedName)
        .maybeSingle();

    // Case A: 완전 신규
    if (existingBaseline == null) {
      final newBaseline = ExerciseBaseline(
        id: const Uuid().v4(),
        userId: userId,
        exerciseName: trimmedName,
        bodyPart: BodyPartParsing.fromCode(bodyPartCode),
        targetMuscles: targetMuscles.isEmpty ? null : targetMuscles,
        isHiddenFromHome: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await upsertBaseline(newBaseline);
    }

    // Case B: 기존 운동 - 활성화
    final existing = ExerciseBaseline.fromJson(existingBaseline);

    final updateData = <String, dynamic>{
      'is_hidden_from_home': false,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.bodyPart == null && bodyPartCode.trim().isNotEmpty) {
      updateData['body_part'] = bodyPartCode.trim();
    }

    final existingMuscles = existing.targetMuscles ?? const <String>[];
    if (existingMuscles.isEmpty && targetMuscles.isNotEmpty) {
      updateData['target_muscles'] = targetMuscles;
    }

    await client
        .from('exercise_baselines')
        .update(updateData)
        .eq('id', existing.id)
        .eq('user_id', userId);

    // Recover Sets callback (세트 복구는 WorkoutSetRepository가 담당)
    if (recoverCallback != null) {
      await recoverCallback(existing.id);
    }

    final updatedBaseline = await getBaselineById(existing.id);
    return updatedBaseline ?? existing;
  }

  /// Baseline의 영상 URL 업데이트
  Future<void> updateBaselineVideo(
    String baselineId,
    String videoUrl,
    String? thumbnailUrl,
  ) async {
    final userId = currentUserId;

    final updateData = <String, dynamic>{
      'video_url': videoUrl,
    };

    if (thumbnailUrl != null) {
      updateData['thumbnail_url'] = thumbnailUrl;
    }

    await client
        .from('exercise_baselines')
        .update(updateData)
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 영상 파일 업로드
  Future<String> uploadVideo(File videoFile, String baselineId) async {
    final userId = currentUserId;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${AppConstants.videoExtension}';
    final filePath = '$userId/$baselineId/$fileName';

    await storage.upload(filePath, videoFile);

    return storage.getPublicUrl(filePath);
  }

  /// 썸네일 이미지 업로드
  Future<String> uploadThumbnail(File thumbnailFile, String baselineId) async {
    final userId = currentUserId;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${AppConstants.imageExtension}';
    final filePath = '$userId/$baselineId/$fileName';

    await storage.upload(filePath, thumbnailFile);

    return storage.getPublicUrl(filePath);
  }

  /// 운동 삭제 (연쇄 삭제 - RPC 함수 호출)
  Future<void> deleteBaseline(String baselineId, String exerciseName) async {
    final userId = currentUserId;

    await client.rpc('delete_exercise_cascade', params: {
      'p_baseline_id': baselineId,
      'p_exercise_name': exerciseName,
      'p_user_id': userId,
    });
  }

  /// ID 목록으로 운동 정보 일괄 조회
  Future<List<ExerciseBaseline>> getBaselinesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final userId = currentUserIdOrNull;
    if (userId == null) return [];

    final response = await client
        .from('exercise_baselines')
        .select()
        .eq('user_id', userId)
        .inFilter('id', ids);

    return (response as List).map((e) => ExerciseBaseline.fromJson(e)).toList();
  }

  /// 운동 이름 변경 (모든 관련 테이블 업데이트)
  Future<void> updateExerciseName(String oldName, String newName) async {
    final userId = currentUserId;

    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) {
      throw Exception('운동 이름은 비어있을 수 없습니다.');
    }

    // 1. exercise_baselines 테이블 업데이트
    await client
        .from('exercise_baselines')
        .update({
          'exercise_name': trimmedNewName,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('exercise_name', oldName);

    // 2. planned_workouts 테이블 업데이트
    await client
        .from('planned_workouts')
        .update({'exercise_name': trimmedNewName})
        .eq('user_id', userId)
        .eq('exercise_name', oldName);

    // 3. routine_items 테이블 업데이트
    final routinesResponse = await client
        .from('routines')
        .select('id')
        .eq('user_id', userId);

    final routineIds = (routinesResponse as List)
        .map((r) => r['id'] as String)
        .toList();

    if (routineIds.isNotEmpty) {
      await client
          .from('routine_items')
          .update({'exercise_name': trimmedNewName})
          .inFilter('routine_id', routineIds)
          .eq('exercise_name', oldName);
    }
  }

  /// 홈 화면에서 운동 숨김 처리
  Future<void> hideBaselineFromHome(String baselineId) async {
    final userId = currentUserId;

    await client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 홈 화면에서 운동 표시 (숨김 해제)
  Future<void> showBaselineOnHome(String baselineId) async {
    final userId = currentUserId;

    await client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 운동 순서 변경 DB 저장
  Future<void> persistWorkoutOrder(List<String> baselineIds) async {
    final userId = currentUserId;
    if (baselineIds.isEmpty) return;

    final now = DateTime.now();

    for (int i = 0; i < baselineIds.length; i++) {
      final newCreatedAt = now.add(Duration(milliseconds: i));

      await client
          .from('exercise_baselines')
          .update({
            'created_at': newCreatedAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', baselineIds[i])
          .eq('user_id', userId);
    }
  }
}
