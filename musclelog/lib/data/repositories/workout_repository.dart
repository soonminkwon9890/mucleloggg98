import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/exercise_baseline.dart';
import '../models/workout_set.dart';
import '../models/check_point.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';
import '../services/supabase_service.dart';
import '../../core/constants/app_constants.dart';

/// 운동 데이터 레포지토리
class WorkoutRepository {
  final _client = SupabaseService.client;
  final _storage = SupabaseService.storageBucket;

  // [Phase 1.1] 프로필 체크 최적화: 유저 ID 기반 캐싱 (재로그인 시나리오 대응)
  String? _lastCheckedUserId;

  /// 프로필 존재 여부 확인 및 생성 (Safety Net)
  /// [중요] DB 쓰기 작업 전에 호출하여 foreign key constraint 에러 방지
  /// [최적화] 유저 ID 캐싱으로 중복 체크 방지
  Future<void> _ensureProfileExists() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 이미 체크한 유저라면 패스 (네트워크 요청 0회)
    if (_lastCheckedUserId == currentUser.id) return;

    try {
      // profiles 테이블에서 현재 유저 조회
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      // 프로필이 없으면 기본 프로필 생성
      if (existingProfile == null) {
        await _client.from('profiles').insert({
          'id': currentUser.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      // 체크 완료된 유저 ID 저장
      _lastCheckedUserId = currentUser.id;
    } catch (e) {
      // 프로필 생성 실패 시에도 계속 진행 (이미 존재하는 경우 등)
      // 실제 foreign key constraint는 다음 작업에서 확인됨
      // 에러는 조용히 무시 (Safety Net이므로 실패해도 다음 작업에서 처리됨)
    }
  }

  /// 운동 기준 정보 저장/수정 통합 (Upsert)
  /// [Phase 1.2] saveBaseline + updateBaseline 통합
  /// ID 존재 여부에 따라 자동으로 Insert/Update 처리
  Future<ExerciseBaseline> upsertBaseline(ExerciseBaseline baseline) async {
    await _ensureProfileExists();
    final userId = _client.auth.currentUser!.id;

    final data = baseline.toJson();
    data['user_id'] = userId;

    // [중요] 수정(Update) 상황이라도 created_at이 null이 되지 않도록 주의
    // 신규 생성일 때만 현재 시간, 기존 객체면 기존 시간 유지
    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toIso8601String();
    } else if (data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    // updated_at은 항상 현재 시간으로 갱신
    data['updated_at'] = DateTime.now().toIso8601String();
    
    // 관계형 데이터 제거 (DB 저장 시 불필요)
    data.remove('workout_sets');

    // upsert: ID가 있으면 Update, 없으면 Insert
    final response = await _client
        .from('exercise_baselines')
        .upsert(data)
        .select()
        .single();

    return ExerciseBaseline.fromJson(response);
  }

  /// [Deprecated] 운동 기준 정보 저장 - upsertBaseline 사용 권장
  @Deprecated('Use upsertBaseline instead')
  Future<ExerciseBaseline> saveBaseline(ExerciseBaseline baseline) async {
    // 하위 호환성을 위해 내부에서 upsertBaseline 호출
    return upsertBaseline(baseline.copyWith(id: const Uuid().v4()));
  }

  /// 사용자의 모든 운동 기준 정보 가져오기 (조인 쿼리 사용)
  /// [수정] 숨김 처리된 운동 제외 + 성능 최적화 (최신 100개만 조회)
  Future<List<ExerciseBaseline>> getBaselines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 조인 쿼리: exercise_baselines와 workout_sets를 함께 가져오기
    // 날짜 필터링은 클라이언트 측(Home Screen)에서 수행
    final response = await _client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('is_hidden_from_home', false) // 숨김 처리된 운동 제외
        .order('updated_at', ascending: false) // [보완] 최근에 업데이트된 운동이 위로 오게
        .limit(100); // 성능 최적화: 최신 100개만 조회

    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();
  }

  /// 보관함용 운동 목록 조회 (완료된 세트가 있는 운동만 반환)
  Future<List<ExerciseBaseline>> getArchivedBaselines() async {
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

    // 완료된 세트가 하나라도 있는 운동만 필터링
    // [중요] 신규 추가만 하고 저장하지 않은 운동은 보관함에 표시하지 않음
    return (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .where((baseline) {
      // 세트가 없으면 제외 (신규 추가 직후 상태)
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        return false;
      }
      // is_completed가 true인 세트가 최소 하나 이상 있어야 포함
      // (저장 버튼을 눌러서 실제로 기록된 운동만 보관함에 표시)
      return baseline.workoutSets!.any((set) => set.isCompleted == true);
    }).toList();
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

  /// 같은 이름/부위/타입의 운동이 있는지 확인
  Future<ExerciseBaseline?> findDuplicateBaseline({
    required String exerciseName,
    required String? bodyPart, // DB 코드 (Enum.code) 또는 null
    required String? movementType, // DB 코드 (Enum.code) 또는 null
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    var query = _client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (bodyPart != null) {
      query = query.eq('body_part', bodyPart);
    } else {
      query = query.isFilter('body_part', null);
    }

    if (movementType != null) {
      query = query.eq('movement_type', movementType);
    } else {
      query = query.isFilter('movement_type', null);
    }

    final response = await query.maybeSingle();
    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
  }

  /// [Deprecated] 기존 운동의 상태 업데이트 - upsertBaseline 사용 권장
  @Deprecated('Use upsertBaseline instead')
  Future<void> updateBaseline(ExerciseBaseline baseline) async {
    // 하위 호환성을 위해 내부에서 upsertBaseline 호출
    await upsertBaseline(baseline);
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

  /// [Deprecated] 운동 세트 기록 저장 - upsertWorkoutSet 사용 권장
  @Deprecated('Use upsertWorkoutSet instead')
  Future<WorkoutSet> saveWorkoutSet(WorkoutSet workoutSet) async {
    // 하위 호환성을 위해 내부에서 upsertWorkoutSet 호출
    return upsertWorkoutSet(workoutSet);
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
    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

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

  /// 특정 운동의 날짜별 기록 조회 (운동 보관함 UI용)
  /// 운동명으로 모든 세트를 조회하고 날짜별로 그룹화하여 반환
  Future<Map<String, List<WorkoutSet>>> getHistoryByExerciseName(
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

    // 모든 baseline_id에 대한 세트 조회 (완료된 세트만)
    final allSets = <WorkoutSet>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('workout_sets')
            .select()
            .eq('baseline_id', baselineId)
            .eq('is_completed', true)
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

    // 날짜별로 그룹화 (yyyy-MM-dd 형식)
    final Map<String, List<WorkoutSet>> groupedByDate = {};
    for (final set in allSets) {
      if (set.createdAt == null) continue;

      final dateKey = DateFormat('yyyy-MM-dd').format(set.createdAt!);
      groupedByDate.putIfAbsent(dateKey, () => []).add(set);
    }

    // 각 날짜별 리스트를 시간순으로 정렬
    for (final key in groupedByDate.keys) {
      groupedByDate[key]!.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    }

    return groupedByDate;
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

  /// 루틴 저장
  Future<Routine> saveRoutine(Routine routine, List<RoutineItem> items) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

    final routineData = routine.toJson();
    routineData['user_id'] = userId;

    // DateTime 필드를 ISO 8601 문자열로 변환
    if (routineData['created_at'] != null &&
        routineData['created_at'] is DateTime) {
      routineData['created_at'] =
          (routineData['created_at'] as DateTime).toIso8601String();
    }

    final routineResponse =
        await _client.from('routines').insert(routineData).select().single();

    final savedRoutine = Routine.fromJson(routineResponse);

    // RoutineItem 저장
    for (var item in items) {
      final itemData = item.toJson();
      itemData['routine_id'] = savedRoutine.id;
      if (itemData['created_at'] != null &&
          itemData['created_at'] is DateTime) {
        itemData['created_at'] =
            (itemData['created_at'] as DateTime).toIso8601String();
      }
      await _client.from('routine_items').insert(itemData);
    }

    final result = await getRoutineById(savedRoutine.id);
    return result ?? savedRoutine;
  }

  /// 사용자의 모든 루틴 조회 (Join 쿼리로 RoutineItem 포함)
  Future<List<Routine>> getRoutines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('routines')
        .select('*, routine_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Routine.fromJson(json)).toList();
  }

  /// 특정 루틴 조회 (Join 쿼리로 RoutineItem 포함)
  Future<Routine?> getRoutineById(String id) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('routines')
        .select('*, routine_items(*)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return Routine.fromJson(response);
  }

  /// 루틴 수정
  Future<Routine> updateRoutine(
      String id, Routine routine, List<RoutineItem> items) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final routineData = routine.toJson();
    routineData.remove('id'); // id는 업데이트하지 않음
    routineData.remove('user_id'); // user_id는 업데이트하지 않음
    routineData.remove('routine_items'); // 조인 필드는 제외

    await _client
        .from('routines')
        .update(routineData)
        .eq('id', id)
        .eq('user_id', userId);

    // 기존 RoutineItem 삭제 후 새로 추가
    await _client.from('routine_items').delete().eq('routine_id', id);

    for (var item in items) {
      final itemData = item.toJson();
      itemData['routine_id'] = id;
      if (itemData['created_at'] != null &&
          itemData['created_at'] is DateTime) {
        itemData['created_at'] =
            (itemData['created_at'] as DateTime).toIso8601String();
      }
      await _client.from('routine_items').insert(itemData);
    }

    final result = await getRoutineById(id);
    return result ?? routine;
  }

  /// 루틴 삭제 (과거 운동 기록 보존)
  ///
  /// 삭제 순서 (중요!):
  /// 1. exercise_baselines의 routine_id를 null로 업데이트 (과거 기록 보존)
  /// 2. routine_items 삭제
  /// 3. routines 삭제
  ///
  /// 주의: 이 순서를 지키지 않으면 FK 제약조건 위반 또는 데이터 손실 발생 가능
  Future<void> deleteRoutine(String routineId) async {
    try {
      // 1. [중요] 이 루틴으로 수행한 과거 운동 기록의 routine_id를 null로 업데이트
      //    -> 과거 기록(exercise_baselines, workout_sets)은 보존됨
      //    -> FK 제약조건 우회
      await _client
          .from('exercise_baselines')
          .update({'routine_id': null}).eq('routine_id', routineId);

      // 2. routine_items 삭제 (루틴 구성 정보)
      //    [방어 로직] routine_items를 참조하는 다른 테이블이 있다면 오류 발생
      await _client.from('routine_items').delete().eq('routine_id', routineId);

      // 3. routines 삭제 (루틴 메타데이터)
      await _client.from('routines').delete().eq('id', routineId);
    } catch (e) {
      throw Exception('루틴 삭제 실패: $e');
    }
  }

  /// 당일 운동 추가 (초기값 0kg, 0회, 0세트로 WorkoutSet 생성)
  /// [initialWeight]와 [initialReps]가 제공되면 해당 값으로 초기 세트를 생성합니다.
  /// 오늘의 운동에 추가 (충돌 방지 - Cloning)
  /// [수정] 기존 baseline을 복제하여 새로운 ID로 저장하여 충돌 방지
  Future<ExerciseBaseline> addTodayWorkout(
    ExerciseBaseline baseline, {
    double? initialWeight,
    int? initialReps,
    String? routineId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

    // [중복 키 오류 방지] 새로운 ID와 현재 시각으로 새 객체 생성
    // [수정] isHiddenFromHome을 false로 설정하여 홈에 표시
    final newBaseline = baseline.copyWith(
      id: const Uuid().v4(), // [필수] 새로운 UUID 발급
      routineId: routineId, // 루틴에서 불러올 때만 설정, 단일 추가 시 null
      isHiddenFromHome: false, // [추가] 홈 화면에 표시
      createdAt: DateTime.now(),
      workoutSets: null, // 빈 리스트로 시작 (0세트)
    );

    // Baseline 저장
    final savedBaseline = await upsertBaseline(newBaseline);

    // 초기값 설정 (제공된 값이 있으면 사용, 없으면 0)
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

    final result = await getBaselineById(savedBaseline.id);
    return result ?? savedBaseline;
  }

  /// 세트 수정
  /// [Deprecated] 운동 세트 기록 업데이트 - upsertWorkoutSet 사용 권장
  @Deprecated('Use upsertWorkoutSet instead')
  Future<WorkoutSet> updateWorkoutSet(WorkoutSet set) async {
    // 하위 호환성을 위해 내부에서 upsertWorkoutSet 호출
    return upsertWorkoutSet(set);
  }

  /// WorkoutSet Upsert (Insert or Update) - 통합 메서드
  /// [Phase 1.3] saveWorkoutSet + updateWorkoutSet 통합
  /// ID가 존재하면 Update, 없으면 Insert
  Future<WorkoutSet> upsertWorkoutSet(WorkoutSet set) async {
    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

    final data = set.toJson();
    data['baseline_id'] = set.baselineId;

    // [Fix] DB 컬럼명 강제 매핑
    data['is_completed'] = set.isCompleted;

    // [중요] created_at 처리: null이면 현재 시간, 있으면 기존 시간 유지
    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toIso8601String();
    } else if (data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    // Supabase upsert 사용 (ID 기반으로 자동 Insert/Update)
    final response = await _client
        .from('workout_sets')
        .upsert(data)
        .select()
        .single();

    return WorkoutSet.fromJson(response);
  }

  /// 세트 일괄 저장 (Batch Insert/Update)
  /// [Phase 1.3] 루틴 불러올 때 성능 향상
  Future<void> batchSaveWorkoutSets(List<WorkoutSet> sets) async {
    if (sets.isEmpty) return;
    await _ensureProfileExists();

    final dataList = sets.map((s) {
      final json = s.toJson();
      // [보완] 필수: 각 세트별로 날짜 확인
      // 신규 세트(ID 없음)는 현재 시간, 기존 세트(ID 있음)는 기존 시간 유지
      if (json['created_at'] == null) {
        json['created_at'] = DateTime.now().toIso8601String();
      } else if (json['created_at'] is DateTime) {
        json['created_at'] = (json['created_at'] as DateTime).toIso8601String();
      }
      // baseline_id 필수 필드 확인
      json['baseline_id'] = s.baselineId;
      // is_completed 명시적 매핑
      json['is_completed'] = s.isCompleted;
      return json;
    }).toList();

    await _client.from('workout_sets').upsert(dataList);
  }

  /// 루틴 실행 이력 조회
  Future<Map<String, List<ExerciseBaseline>>> getRoutineExecutionHistory(
      String routineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('exercise_baselines')
        .select('*, workout_sets(*)')
        .eq('user_id', userId)
        .eq('routine_id', routineId)
        .order('created_at', ascending: false);

    final baselines = (response as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();

    // 날짜별로 그룹화
    final Map<String, List<ExerciseBaseline>> grouped = {};
    for (final baseline in baselines) {
      if (baseline.createdAt == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(baseline.createdAt!);
      grouped.putIfAbsent(dateKey, () => []).add(baseline);
    }

    return grouped;
  }

  /// 루틴에 운동 추가
  /// [중요] sort_order는 기존 루틴 아이템들의 최댓값(Max)을 조회하여 +1씩 증가
  /// [중요] 루틴은 템플릿이므로 weight, reps, sets 같은 수행 데이터는 저장하지 않음
  Future<void> addExercisesToRoutine(
    String routineId,
    List<String> baselineIds,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

    // 1. 기존 routine_items의 sort_order 최댓값 조회
    final existingItemsResponse = await _client
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

    // 2. 선택된 baseline들을 RoutineItem으로 변환
    final baselines = await getBaselines();
    final selectedBaselines =
        baselines.where((b) => baselineIds.contains(b.id)).toList();

    // 3. sort_order를 순차적으로 부여하여 추가
    // [중요] 루틴은 템플릿이므로 exercise_name, body_part, movement_type만 저장
    for (int i = 0; i < selectedBaselines.length; i++) {
      final baseline = selectedBaselines[i];
      final item = RoutineItem(
        id: const Uuid().v4(),
        routineId: routineId,
        exerciseName: baseline.exerciseName,
        bodyPart: baseline.bodyPart,
        movementType: baseline.movementType,
        sortOrder: startSortOrder + i, // 최댓값 + 1부터 시작
        createdAt: DateTime.now(),
      );

      final itemData = item.toJson();
      itemData['routine_id'] = routineId;
      if (itemData['created_at'] != null &&
          itemData['created_at'] is DateTime) {
        itemData['created_at'] =
            (itemData['created_at'] as DateTime).toIso8601String();
      }

      await _client.from('routine_items').insert(itemData);
    }
  }

  /// 세트 삭제
  Future<void> deleteWorkoutSet(String setId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // workout_sets에서 삭제
    await _client.from('workout_sets').delete().eq('id', setId);
  }

  /// Smart Delete: 저장된 기록이 있으면 숨김, 없으면 삭제
  /// [수정] 물리적 삭제와 논리적 삭제를 구분하여 데이터 무결성 보장
  Future<void> deleteTodayWorkoutsByBaseline(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 확인 (삭제 전 에러 방지)
    await _ensureProfileExists();

    // 완료된 세트가 있는지 확인
    final completedSetsResponse = await _client
        .from('workout_sets')
        .select('id')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true)
        .limit(1);

    final hasCompletedSets = (completedSetsResponse as List).isNotEmpty;

    if (hasCompletedSets) {
      // 기록이 있으면 숨김 처리 (논리적 삭제 - 보관함 데이터 보존)
      await _client
          .from('exercise_baselines')
          .update({'is_hidden_from_home': true})
          .eq('id', baselineId)
          .eq('user_id', userId);
    } else {
      // 기록이 없으면 완전 삭제 (물리적 삭제 - Cascade로 세트도 자동 삭제)
      await _client
          .from('exercise_baselines')
          .delete()
          .eq('id', baselineId)
          .eq('user_id', userId);
    }
  }

  /// 특정 운동이 포함된 루틴 조회
  /// [주의] exercise_name으로 routine_items를 조회하여 루틴 정보 반환
  Future<List<Routine>> getRoutinesByExerciseName(String exerciseName) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // routine_items에서 exercise_name으로 조회
    final itemsResponse = await _client
        .from('routine_items')
        .select('routine_id')
        .eq('exercise_name', exerciseName);

    if (itemsResponse.isEmpty) return [];

    final routineIds = (itemsResponse as List)
        .map((item) => item['routine_id'] as String)
        .toSet()
        .toList();

    // 각 routine_id로 루틴 조회
    final routines = <Routine>[];
    for (final routineId in routineIds) {
      final routine = await getRoutineById(routineId);
      if (routine != null) {
        routines.add(routine);
      }
    }

    return routines;
  }

  /// 운동 삭제 (연쇄 삭제 - RPC 함수 호출)
  /// [중요] Supabase Database Function을 사용하여 트랜잭션 보장
  /// 사전에 Supabase SQL Editor에서 delete_exercise_cascade 함수를 생성해야 함
  Future<void> deleteBaseline(String baselineId, String exerciseName) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // RPC 함수 호출
    await _client.rpc('delete_exercise_cascade', params: {
      'p_baseline_id': baselineId,
      'p_exercise_name': exerciseName,
      'p_user_id': userId, // 보안 강화를 위해 필수
    });
  }

  /// 오늘 날짜의 특정 운동 세트 기록 조회
  Future<List<WorkoutSet>> getTodayWorkoutSets(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final response = await _client
        .from('workout_sets')
        .select('*')
        .eq('baseline_id', baselineId)
        .eq('user_id', userId)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String())
        .order('created_at', ascending: true);

    return (response as List).map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// 특정 운동의 수행 일수 조회 (완료된 세트가 있는 고유한 날짜 개수)
  Future<int> getExerciseFrequency(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 완료된 세트만 조회
    final response = await _client
        .from('workout_sets')
        .select('created_at')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true);

    // 날짜별로 그룹핑하여 고유한 날짜 개수 계산
    // [수정] .toLocal() 제거 - 날짜를 있는 그대로 사용
    final dates = (response as List).map((item) {
      final createdAt = DateTime.parse(item['created_at']);
      // 날짜를 있는 그대로 문자열로 변환 (변환 없이 Raw Data 사용)
      return DateFormat('yyyy-MM-dd').format(createdAt);
    }).toSet();

    return dates.length;
  }

  /// 과거 날짜의 세트 데이터를 오늘 날짜로 복사
  Future<void> copySetsToToday(
      String baselineId, List<WorkoutSet> pastSets) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 존재 확인
    await _ensureProfileExists();

    // [중요] 세트 순서 보장: sets 필드 또는 created_at 기준으로 정렬
    final sortedSets = List<WorkoutSet>.from(pastSets);
    sortedSets.sort((a, b) {
      // sets 필드를 기준으로 정렬
      final setsComparison = a.sets.compareTo(b.sets);
      if (setsComparison != 0) {
        return setsComparison;
      }
      // sets가 같으면 created_at 기준으로 정렬
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      return 0;
    });

    // pastSets를 반복문으로 돌면서 새로운 세트 생성
    for (int i = 0; i < sortedSets.length; i++) {
      final pastSet = sortedSets[i];
      final newSet = WorkoutSet(
        id: const Uuid().v4(), // 새로운 ID
        baselineId: baselineId, // 기존 ID 유지
        weight: pastSet.weight, // 과거 값 복사
        reps: pastSet.reps, // 과거 값 복사
        sets: i + 1, // 순차적으로 재할당 (1, 2, 3...)
        isCompleted: false, // 아직 안 함 (수정 가능한 상태)
        createdAt: DateTime.now(), // 오늘 날짜
      );

      // DB에 insert (일괄 저장)
      final setData = newSet.toJson();
      setData['baseline_id'] = baselineId;
      setData['is_completed'] = false;

      if (setData['created_at'] != null && setData['created_at'] is DateTime) {
        setData['created_at'] =
            (setData['created_at'] as DateTime).toIso8601String();
      }

      await _client.from('workout_sets').insert(setData);
    }

    // [중요] ExerciseBaseline 상태 업데이트: 홈 화면 상단에 즉시 표시
    await _client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
  }

  /// 홈 화면 운동들을 루틴으로 일괄 저장
  /// [중요] 모든 세트를 is_completed = true로 확정하여 Smart Delete 보호
  Future<void> saveRoutineFromWorkouts(
    String routineName,
    List<ExerciseBaseline> baselines,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // [Safety Net] 프로필 확인
    await _ensureProfileExists();

    // 1. 모든 운동의 세트를 is_completed = true로 저장 (일괄 처리)
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
    
    // [Phase 1.4] 일괄 저장으로 성능 향상
    if (allSetsToSave.isNotEmpty) {
      await batchSaveWorkoutSets(allSetsToSave);
    }

    // 2. 루틴 생성
    final routine = Routine(
      id: const Uuid().v4(),
      userId: userId,
      name: routineName,
      createdAt: DateTime.now(),
    );

    final routineData = routine.toJson();
    if (routineData['created_at'] != null &&
        routineData['created_at'] is DateTime) {
      routineData['created_at'] =
          (routineData['created_at'] as DateTime).toIso8601String();
    }

    await _client.from('routines').insert(routineData);

    // 3. RoutineItem 생성 및 저장 (일괄 처리)
    final itemsData = <Map<String, dynamic>>[];
    for (int i = 0; i < baselines.length; i++) {
      final baseline = baselines[i];
      final item = RoutineItem(
        id: const Uuid().v4(),
        routineId: routine.id,
        exerciseName: baseline.exerciseName,
        bodyPart: baseline.bodyPart,
        movementType: baseline.movementType,
        sortOrder: i,
        createdAt: DateTime.now(),
      );

      final itemData = item.toJson();
      itemData['routine_id'] = routine.id;
      if (itemData['created_at'] != null &&
          itemData['created_at'] is DateTime) {
        itemData['created_at'] =
            (itemData['created_at'] as DateTime).toIso8601String();
      }

      itemsData.add(itemData);
    }
    
    // [Phase 1.4] 루틴 아이템 일괄 저장
    if (itemsData.isNotEmpty) {
      await _client.from('routine_items').insert(itemsData);
    }

    // 4. exercise_baselines의 routine_id 업데이트 (일괄 처리)
    final baselineIds = baselines.map((b) => b.id).toList();
    if (baselineIds.isNotEmpty) {
      for (final baselineId in baselineIds) {
        await _client
            .from('exercise_baselines')
            .update({'routine_id': routine.id})
            .eq('id', baselineId)
            .eq('user_id', userId);
      }
    }
  }
}
