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
import '../services/supabase_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/enums/exercise_enums.dart';

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
    final response =
        await _client.from('exercise_baselines').upsert(data).select().single();

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

  /// 오늘 날짜의 운동 기준 정보 가져오기
  /// [리팩토링] getWorkoutsByDate를 재사용하여 날짜 처리 통일
  Future<List<ExerciseBaseline>> getTodayBaselines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    final today = DateTime.now();
    // 로컬 기준 자정으로 정규화
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // getWorkoutsByDate를 재사용하여 날짜 처리 통일
    return await getWorkoutsByDate(normalizedToday);
  }

  /// 날짜 변경 시 홈 화면 초기화 (선택 사항)
  /// 어제 이전의 완료된 운동을 숨김 처리
  Future<void> resetHomeForNewDay() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();

    // 어제 이전의 완료된 세트를 가진 baseline 찾기
    final response = await _client
        .from('exercise_baselines')
        .select('id, workout_sets(*)')
        .eq('user_id', userId)
        .eq('is_hidden_from_home', false);

    // 오늘 날짜가 아닌 완료된 세트만 있는 baseline을 숨김 처리
    for (final baseline in response as List) {
      final workoutSets = baseline['workout_sets'] as List?;
      if (workoutSets == null || workoutSets.isEmpty) continue;

      final hasTodaySets = workoutSets.any((set) {
        if (set['created_at'] == null) return false;
        final createdAt = DateTime.parse(set['created_at']);
        return DateFormatter.isSameDate(createdAt, today);
      });

      if (!hasTodaySets) {
        await _client
            .from('exercise_baselines')
            .update({'is_hidden_from_home': true}).eq('id', baseline['id']);
      }
    }
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

    final response = await query.maybeSingle();
    if (response == null) return null;

    return ExerciseBaseline.fromJson(response);
  }

  /// 운동 추가/활성화 통합 메서드 (신규 생성 및 기존 복구)
  /// 운동 이름으로 기존 운동을 찾거나 생성하고, 오늘 날짜의 홈 화면에 노출되도록 처리합니다.
  /// 
  /// [기능]
  /// - 이름으로만 검색 (대소문자 구분 없음)
  /// - 신규 운동: 생성 및 INSERT
  /// - 기존 운동: Unhide + (필요 시) Metadata 보강 + Recover Sets
  Future<ExerciseBaseline> ensureExerciseVisible(
    String name,
    String bodyPartCode,
    List<String> targetMuscles,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _ensureProfileExists();

    // 1. 입력값 정제: 이름 앞뒤 공백 제거
    final trimmedName = name.trim();

    // 2. 조회: 이름으로만 기존 운동 검색 (대소문자 구분 없음)
    final existingBaseline = await _client
        .from('exercise_baselines')
        .select('*')
        .eq('user_id', userId)
        .ilike('exercise_name', trimmedName)
        .maybeSingle();

    // Case A: 완전 신규 - 조회 결과 없음
    if (existingBaseline == null) {
      // 새 ExerciseBaseline 생성 및 INSERT
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

      final savedBaseline = await upsertBaseline(newBaseline);
      return savedBaseline;
    }

    // Case B: 기존 운동 - 조회 결과 있음
    final existing = ExerciseBaseline.fromJson(existingBaseline);

    // Unhide: is_hidden_from_home을 false로 UPDATE
    // Update Metadata: 절대 기존 metadata를 지우지 않음
    // - body_part / target_muscles 는 persistent 데이터이므로, 값이 비어있을 때만 '보강'한다.
    // Refresh Timestamp: updated_at 갱신
    final updateData = <String, dynamic>{
      'is_hidden_from_home': false,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // body_part 보강: 기존 값이 없고 입력이 유효할 때만 채움 (덮어쓰기 금지)
    if (existing.bodyPart == null && bodyPartCode.trim().isNotEmpty) {
      updateData['body_part'] = bodyPartCode.trim();
    }

    // target_muscles 보강: 기존 값이 비어있고 입력이 있을 때만 채움 (빈 리스트로 덮어쓰기 금지)
    final existingMuscles = existing.targetMuscles ?? const <String>[];
    if (existingMuscles.isEmpty && targetMuscles.isNotEmpty) {
      updateData['target_muscles'] = targetMuscles;
    }

    await _client
        .from('exercise_baselines')
        .update(updateData)
        .eq('id', existing.id)
        .eq('user_id', userId);

    // Recover Sets: 해당 객체의 id를 사용하여 recoverOrAddExercise 호출 (오늘 날짜 기준)
    await recoverOrAddExercise(existing.id);

    // 업데이트된 객체 반환
    final updatedBaseline = await getBaselineById(existing.id);
    return updatedBaseline ?? existing;
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
  /// [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id만 사용
  Future<List<WorkoutSet>> getWorkoutSets(String baselineId) async {
    final response = await _client
        .from('workout_sets')
        .select()
        .eq('baseline_id', baselineId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// 최근 세트 기록 가져오기
  /// [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id만 사용
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
        // [수정] is_completed가 true인 세트만 조회 (완료된 운동만 캘린더에 표시)
        final response = await _client
            .from('workout_sets')
            .select('created_at')
            .eq('baseline_id', baselineId)
            .eq('is_completed', true); // [추가] 완료된 세트만 조회

        for (final item in response as List) {
          final createdAt = item['created_at'] as String?;
          if (createdAt != null) {
            try {
              // UTC → Local 변환 후 날짜 추출 (타임존 이슈 방지)
              final localDateTime = DateTime.parse(createdAt).toLocal();
              final dateOnly =
                  DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
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
  /// 넓은 범위 조회 + 로컬 단순 비교 전략 (타임존 계산 제거)
  Future<List<ExerciseBaseline>> getWorkoutsByDate(DateTime date) async {
    // Note: workoutSets contains only the sets for the queried date
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 타겟 날짜 (년/월/일만 사용)
    final targetYear = date.year;
    final targetMonth = date.month;
    final targetDay = date.day;

    // 무조건 넉넉하게 가져옴 (전전날부터 모레까지: ±2일)
    final bufferStart = date.subtract(const Duration(days: 2)).toUtc().toIso8601String();
    final bufferEnd = date.add(const Duration(days: 2)).toUtc().toIso8601String();

    // Step 1) Fetch Sets (Daily & Completed Only)
    // workout_sets에는 user_id가 없으므로 exercise_baselines로 inner join 하여 user 범위를 제한합니다.
    final setsResponse = await _client
        .from('workout_sets')
        .select(
          'id, baseline_id, weight, reps, sets, rpe, rpe_level, estimated_1rm, is_ai_suggested, performance_score, is_completed, is_hidden, created_at, exercise_baselines!inner(user_id)',
        )
        .gte('created_at', bufferStart)
        .lte('created_at', bufferEnd)
        .eq('is_completed', true)
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId)
        .order('created_at', ascending: true);

    if (setsResponse.isEmpty) {
      return [];
    }

    // baseline_id -> 해당 날짜의 세트들
    // Dart 메모리 필터링: toLocal()로 변환 후 '년/월/일'만 비교
    final Map<String, List<WorkoutSet>> dailySetsByBaselineId = {};
    for (final row in (setsResponse as List)) {
      if (row is! Map<String, dynamic>) continue;
      
      // 날짜 필터링: DB 시간을 로컬로 변환 후 '년/월/일'만 비교
      final createdAtStr = row['created_at'] as String?;
      if (createdAtStr == null) continue;
      
      // DB 시간이 무엇이든 내 폰 시간(Local)으로 바꿈
      final itemTime = DateTime.parse(createdAtStr).toLocal();
      
      // 시간/분/초 무시하고 날짜만 같으면 OK
      if (itemTime.year != targetYear ||
          itemTime.month != targetMonth ||
          itemTime.day != targetDay) {
        continue; // 타겟 날짜가 아니면 스킵
      }
      
      final rowMap = Map<String, dynamic>.from(row);
      // inner join 결과는 WorkoutSet 모델에 없으므로 제거(파싱 에러 방지)
      rowMap.remove('exercise_baselines');

      final set = WorkoutSet.fromJson(rowMap);
      dailySetsByBaselineId.putIfAbsent(set.baselineId, () => []).add(set);
    }

    if (dailySetsByBaselineId.isEmpty) {
      return [];
    }

    final baselineIds = dailySetsByBaselineId.keys.toList();

    // Step 2) Fetch Baselines (History Preservation: 숨김 필터 미적용)
    final baselinesResponse = await _client
        .from('exercise_baselines')
        .select()
        .eq('user_id', userId)
        .inFilter('id', baselineIds);

    final baselines = (baselinesResponse as List)
        .map((json) => ExerciseBaseline.fromJson(json))
        .toList();

    // Step 3) Merge & Return
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
    // [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id만 사용
    final allSets = <WorkoutSet>[];
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('workout_sets')
            .select()
            .eq('baseline_id', baselineId)
            .eq('is_completed', true)
            // Soft Delete 필터: 숨김 처리된 세트는 히스토리에서 제외
            .eq('is_hidden', false)
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
    // UTC → Local 변환 후 날짜 추출 (타임존 이슈 방지)
    final Map<String, List<WorkoutSet>> groupedByDate = {};
    for (final set in allSets) {
      if (set.createdAt == null) continue;

      final localCreatedAt = set.createdAt!.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(localCreatedAt);
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

  /// 특정 주(월~일) 주간 볼륨(kg) 조회 (대시보드용)
  /// - [weekStart] 주의 시작일(월요일). null이면 이번 주 월요일을 기본값으로 사용
  /// - 쿼리 로직: weekStart 기준 월요일 00:00 ~ 일요일 23:59 범위를 계산하여 DB를 조회 (UTC 변환 필수)
  /// - 버퍼 전략: 쿼리 시 월요일-1일 ~ 일요일+1일 범위로 조회 후, toLocal()로 요일 필터링
  /// - 반환: 날짜(로컬 00:00:00) -> 총 볼륨 (7키: 월~일)
  Future<Map<DateTime, double>> getWeeklyVolume({DateTime? weekStart}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // weekStart가 null이면 이번 주 월요일 계산. 시간 성분 제거해 캐시 일관성 유지
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final rawStart = weekStart ??
        todayLocal.subtract(Duration(days: now.weekday - 1));
    final effectiveWeekStart = DateTime(
        rawStart.year, rawStart.month, rawStart.day);

    // weekEnd 계산: weekStart + 6일 (일요일 23:59:59까지)
    final endOfWeek = effectiveWeekStart.add(const Duration(days: 6));

    // 쿼리 범위: 버퍼로 월요일-1일 00:00 ~ 일요일+1일 00:00 (UTC 변환)
    // 버퍼 전략: 타임존 경계 이슈 방지를 위해 여유 범위 설정
    final queryStart = effectiveWeekStart.subtract(const Duration(days: 1));
    final queryEnd = endOfWeek.add(const Duration(days: 1)); // 일요일+1 = 다음 월 00:00
    
    // UTC 변환은 쿼리 실행 직전에 수행 (필수)
    final startUtc = queryStart.toUtc().toIso8601String();
    final endUtc = queryEnd.toUtc().toIso8601String();

    final response = await _client
        .from('workout_sets')
        .select(
            'baseline_id, created_at, weight, reps, exercise_baselines!inner(user_id)')
        .eq('is_completed', true)
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId)
        .gte('created_at', startUtc)
        .lt('created_at', endUtc);

    // 이번 주 월~일 7일 키로 초기화
    final result = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      final d = effectiveWeekStart.add(Duration(days: i));
      result[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    // 쿼리 결과를 로컬 시간으로 변환하여 해당 주차에 포함되는지 확인
    for (final row in (response as List)) {
      if (row is! Map) continue;
      final createdAtRaw = row['created_at'];
      if (createdAtRaw == null) continue;

      final createdAtLocal = DateTime.parse(createdAtRaw.toString()).toLocal();
      final dayKey = DateTime(
          createdAtLocal.year, createdAtLocal.month, createdAtLocal.day);

      // 이번 주(월~일)에 해당하는 날만 집계
      if (!result.containsKey(dayKey)) continue;

      final weight = (row['weight'] as num?)?.toDouble() ?? 0.0;
      final reps = (row['reps'] as num?)?.toInt() ?? 0;
      final volume = weight * reps;

      result[dayKey] = (result[dayKey] ?? 0.0) + volume;
    }

    return result;
  }

  /// 특정 주(월~일) 부위 밸런스(8축) 집계 (대시보드용)
  /// - [weekStart] 주의 시작일(월요일). null이면 이번 주 월요일을 기본값으로 사용
  /// - 쿼리 로직: weekStart 기준 월요일 00:00 ~ 일요일 23:59 범위를 계산하여 DB를 조회 (UTC 변환 필수)
  /// - 중복 제거: 같은 날짜(date) + 같은 baseline_id는 1회로 카운트
  /// - 전신(BodyPart.full): 8개 축 모두 +0.2
  /// - 단일/다중 타겟: 축 매핑 후 1을 타겟 수로 분산(+1/N)
  /// - 매칭 불가: '기타'로 분류하되 차트엔 미표시(집계 제외)
  Future<Map<String, double>> getBodyBalance({DateTime? weekStart}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // weekStart가 null이면 이번 주 월요일 계산. 시간 성분 제거해 캐시 일관성 유지
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final rawStart = weekStart ??
        todayLocal.subtract(Duration(days: now.weekday - 1));
    final effectiveWeekStart = DateTime(
        rawStart.year, rawStart.month, rawStart.day);

    // weekEnd 계산: weekStart + 6일 (일요일 23:59:59까지)
    final weekEnd = effectiveWeekStart.add(const Duration(days: 6));
    
    // 쿼리 범위: getWeeklyVolume과 동일한 로직 사용
    final queryStart = effectiveWeekStart.subtract(const Duration(days: 1));
    final queryEnd = weekEnd.add(const Duration(days: 1)); // 일요일+1 = 다음 월 00:00
    
    // UTC 변환은 쿼리 실행 직전에 수행 (필수)
    final startUtc = queryStart.toUtc().toIso8601String();
    final endUtc = queryEnd.toUtc().toIso8601String();

    final response = await _client
        .from('workout_sets')
        .select(
            'baseline_id, created_at, exercise_baselines!inner(user_id, body_part, target_muscles)')
        .eq('is_completed', true)
        .eq('is_hidden', false)
        .eq('exercise_baselines.user_id', userId)
        .gte('created_at', startUtc)
        .lt('created_at', endUtc);

    const axes = [
      '가슴',
      '등',
      '어깨',
      '팔',
      '복근',
      '대퇴사두',
      '햄스트링',
      '둔근',
    ];
    final result = {for (final a in axes) a: 0.0};

    final seen = <String>{}; // yyyy-MM-dd|baselineId

    // 쿼리 결과를 로컬 시간으로 변환하여 해당 주차에 포함되는지 확인
    for (final row in (response as List)) {
      if (row is! Map) continue;
      final baselineId = row['baseline_id']?.toString();
      final createdAtRaw = row['created_at']?.toString();
      if (baselineId == null || createdAtRaw == null) continue;

      final createdAt = DateTime.parse(createdAtRaw).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
      
      // 해당 주차(월~일)에 포함되는지 확인
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
      
      // 주차 범위를 벗어나면 제외
      if (dayKey.isBefore(weekStartNormalized) ||
          dayKey.isAfter(weekEndNormalized)) {
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
        final axis = mapMuscleToAxis(m);
        if (axis != '기타') mappedAxes.add(axis);
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

  /// targetMuscles 문자열을 8개 카테고리로 매핑
  /// - 매칭 안 되면 '기타' 반환 (차트에는 미표시)
  String mapMuscleToAxis(String muscle) {
    final m = muscle.trim();
    if (m.isEmpty) return '기타';

    // 가슴
    if (m.contains('가슴') || m.contains('흉') || m.contains('대흉')) return '가슴';
    // 등
    if (m.contains('등') || m.contains('광배') || m.contains('승모')) return '등';
    // 어깨
    if (m.contains('어깨') || m.contains('삼각')) return '어깨';
    // 팔
    if (m.contains('팔') ||
        m.contains('이두') ||
        m.contains('삼두') ||
        m.contains('전완')) {
      return '팔';
    }
    // 복근/코어
    if (m.contains('복근') || m.contains('코어') || m.contains('복직')) return '복근';
    // 대퇴사두
    if (m.contains('대퇴') || m.contains('사두') || m.contains('쿼드')) return '대퇴사두';
    // 햄스트링
    if (m.contains('햄') || m.contains('햄스트링')) return '햄스트링';
    // 둔근
    if (m.contains('둔근') || m.contains('엉덩')) return '둔근';

    return '기타';
  }

  /// 특정 운동의 날짜별 강도 조회
  /// [exerciseName] 운동 이름
  /// 반환: {"2024-01-23": "hard", "2024-01-22": "easy"} (날짜 형식: yyyy-MM-dd)
  Future<Map<String, String?>> getDifficultyByExerciseName(
    String exerciseName,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    // 1. exercise_name으로 baseline_id들 조회
    final baselinesResponse = await _client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName);

    if (baselinesResponse.isEmpty) return {};

    final baselineIds = (baselinesResponse as List)
        .map((json) => json['id'] as String)
        .toList();

    // 2. workout_sessions에서 baseline_id IN (...) AND difficulty IS NOT NULL 조회
    final Map<String, String?> difficultyMap = {};
    
    for (final baselineId in baselineIds) {
      try {
        final response = await _client
            .from('workout_sessions')
            .select('workout_date, difficulty')
            .eq('baseline_id', baselineId)
            .not('difficulty', 'is', null) // difficulty가 null이 아닌 것만
            .order('workout_date', ascending: false);

        // 3. 결과 매핑 (날짜 포맷 일치 필수)
        for (final row in response as List) {
          final workoutDate = row['workout_date'];
          final difficulty = row['difficulty'] as String?;
          
          if (workoutDate != null && difficulty != null) {
            // workout_date를 DateTime으로 파싱 후 yyyy-MM-dd 형식으로 변환
            final date = workoutDate is String 
                ? DateTime.parse(workoutDate) 
                : DateTime.parse(workoutDate.toString());
            final dateKey = DateFormat('yyyy-MM-dd').format(date); // 포맷 일치 필수
            
            // 이미 해당 날짜에 difficulty가 있으면 유지 (첫 번째 baseline_id 우선)
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
    // [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id만 사용
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

  /// 완료된 운동 기록이 있는 운동 목록 + 수행 날짜 리스트 조회 (프로필 검색용)
  ///
  /// - workout_sets에는 user_id가 없으므로 exercise_baselines를 inner join 하여 user 범위를 제한합니다.
  /// - 날짜는 반드시 toLocal() 후 DateTime(y,m,d)로 정규화하여 중복 제거합니다.
  /// - 반환은 exercise_name 가나다순 정렬입니다.
  Future<List<ExerciseWithHistory>> getExercisesWithHistory() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _client
        .from('workout_sets')
        .select('baseline_id, created_at, exercise_baselines!inner(exercise_name, user_id)')
        .eq('is_completed', true)
        .eq('exercise_baselines.user_id', userId);

    if (response.isEmpty) return [];

    final Map<String, ({String exerciseName, Set<DateTime> dates})>
        grouped = {};

    for (final row in (response as List)) {
      if (row is! Map<String, dynamic>) continue;

      final baselineId = row['baseline_id'] as String?;
      final createdAtRaw = row['created_at'];
      final joined = row['exercise_baselines'];

      if (baselineId == null || baselineId.isEmpty || createdAtRaw == null) {
        continue;
      }

      // join 결과는 List 또는 Map 형태로 올 수 있어 방어적으로 파싱
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
      //    -> 운동 기록 보존을 위해 Baseline 연결을 먼저 끊습니다.
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

    // [중요] 이제 운동 '생성/활성화'는 ensureExerciseVisible이 전담하므로,
    // addTodayWorkout은 "이미 존재하는 운동 ID에 세트만 추가하는 역할"로 축소
    // baseline.id가 존재하는지 확인 (이미 존재하는 운동인지)
    final existing = await getBaselineById(baseline.id);
    if (existing == null) {
      throw Exception('운동이 존재하지 않습니다. ensureExerciseVisible을 사용하여 먼저 운동을 생성/활성화하세요.');
    }

    // 이미 존재하는 운동에 세트만 추가
    final updatedBaseline = existing.copyWith(
      routineId: routineId, // 루틴에서 불러올 때만 설정, 단일 추가 시 null
      updatedAt: DateTime.now(), // 홈 화면 상단 노출을 위해 갱신
    );

    // Baseline 업데이트 (세트는 아래에서 추가)
    final savedBaseline = await upsertBaseline(updatedBaseline);

    // 초기값 설정 (제공된 값이 있으면 사용, 없으면 0)
    if (initialWeight != null || initialReps != null) {
      final initialSet = WorkoutSet(
        id: const Uuid().v4(),
        baselineId: savedBaseline.id,
        weight: initialWeight ?? 0.0,
        reps: initialReps ?? 0,
        sets: 1,
        isCompleted: false,
        createdAt: DateTime.now(), // 단순하게 현재 시간 사용 (upsertWorkoutSet에서 UTC 변환)
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

    // created_at 처리: 단순하게 현재 시간을 UTC로 변환하여 저장
    // (조회 로직이 날짜만 보므로 정규화 불필요)
    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toUtc().toIso8601String();
    }

    // Supabase upsert 사용 (ID 기반으로 자동 Insert/Update)
    final response =
        await _client.from('workout_sets').upsert(data).select().single();

    return WorkoutSet.fromJson(response);
  }

  /// 세트 일괄 저장 (Batch Insert/Update)
  /// [Phase 1.3] 루틴 불러올 때 성능 향상
  Future<void> batchSaveWorkoutSets(List<WorkoutSet> sets) async {
    if (sets.isEmpty) return;
    await _ensureProfileExists();

    final dataList = sets.map((s) {
      final json = s.toJson();
      // 각 세트별로 날짜 확인: 단순하게 UTC로 변환하여 저장
      // (조회 로직이 날짜만 보므로 정규화 불필요)
      if (json['created_at'] == null) {
        json['created_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (json['created_at'] is DateTime) {
        json['created_at'] = (json['created_at'] as DateTime).toUtc().toIso8601String();
      }
      // baseline_id 필수 필드 확인
      json['baseline_id'] = s.baselineId;
      // [중요] is_completed 명시적 매핑 (WorkoutSet의 isCompleted 값을 그대로 사용)
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
    // [중요] 루틴은 템플릿이므로 exercise_name, body_part만 저장
    for (int i = 0; i < selectedBaselines.length; i++) {
      final baseline = selectedBaselines[i];
      final item = RoutineItem(
        id: const Uuid().v4(),
        routineId: routineId,
        exerciseName: baseline.exerciseName,
        bodyPart: baseline.bodyPart,
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
  /// [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 id만 사용
  Future<void> deleteWorkoutSet(String setId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // workout_sets에서 삭제 (user_id 필터 사용 안 함)
    await _client.from('workout_sets').delete().eq('id', setId);
  }

  /// 오늘의 운동 세션 삭제: 오늘 세트 물리 삭제 후 베이스라인 홈 숨김
  /// [Step 1] 날짜 범위 → [Step 2] workout_sets DELETE → [Step 3] exercise_baselines 숨김
  Future<void> deleteTodayWorkoutsByBaseline(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    // 1. 날짜 범위 (getTodayWorkoutSets와 동일)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 2. [Step 2] 연관 세트 선삭제 (Physical Delete)
    // 참고: workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id와 created_at만 사용
    await _client
        .from('workout_sets')
        .delete()
        .eq('baseline_id', baselineId)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String());

    // 3. [Step 3] 본체 숨김 처리 (Soft Delete)
    await _client
        .from('exercise_baselines')
        .update({
          'is_hidden_from_home': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baselineId)
        .eq('user_id', userId);
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

    // [수정] workout_sets 테이블에는 user_id 컬럼이 없으므로 제거
    // [홈 전용] 숨겨진 세트는 조회하지 않음
    final response = await _client
        .from('workout_sets')
        .select('*')
        .eq('baseline_id', baselineId)
        .eq('is_hidden', false)
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
    // [중요] workout_sets 테이블에는 user_id 컬럼이 없으므로 baseline_id만 사용
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

    // pastSets를 반복문으로 돌면서 새로운 세트 생성 (일괄 저장을 위해 리스트에 수집)
    final newSets = <WorkoutSet>[];
    for (int i = 0; i < sortedSets.length; i++) {
      final pastSet = sortedSets[i];
      final newSet = pastSet.copyWith(
        id: const Uuid().v4(), // 새로운 ID
        baselineId: baselineId,
        sets: i + 1, // 순차적으로 재할당
        isCompleted: false, // [강제] 반드시 false로 설정 (저장 전까지 미완료 상태)
        createdAt: DateTime.now(), // 오늘 날짜
      );
      newSets.add(newSet);

      // [검증] isCompleted가 false인지 확인 (디버그용)
      assert(newSet.isCompleted == false, '새로 생성된 세트는 반드시 미완료 상태여야 합니다.');
    }

    // 일괄 저장
    if (newSets.isNotEmpty) {
      await batchSaveWorkoutSets(newSets);
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

  /// 운동 추가/복구 로직 (같은 날짜에 숨겨진 세트 복구)
  /// 신규 운동 추가 시, 입력받은 날짜(Today)에 숨겨진 기록이 있는지 확인하고 복구합니다.
  /// 반환값: true = 복구됨, false = 신규 (기록 없음)
  Future<bool> recoverOrAddExercise(String baselineId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _ensureProfileExists();

    // [보안 검증] baseline_id가 현재 유저의 것인지 확인
    final baselineCheck = await _client
        .from('exercise_baselines')
        .select('id')
        .eq('id', baselineId)
        .eq('user_id', userId)
        .maybeSingle();

    if (baselineCheck == null) {
      throw Exception('해당 운동을 찾을 수 없거나 권한이 없습니다.');
    }

    // [중요] 오늘 날짜 기준으로 포맷팅 (UTC 기준) - deleteWorkoutSetsByDate와 동일한 로직 재사용
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    // Step 1: 동일 날짜 범위 내 숨겨진 세트 조회
    final hiddenSets = await _client
        .from('workout_sets')
        .select('id')
        .eq('baseline_id', baselineId)
        .eq('is_hidden', true)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    // Step 2: 숨겨진 세트가 있으면 복구
    if ((hiddenSets as List).isNotEmpty) {
      // 숨겨진 세트들의 is_hidden을 false로 업데이트
      await _client
          .from('workout_sets')
          .update({'is_hidden': false})
          .eq('baseline_id', baselineId)
          .eq('is_hidden', true)
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      // 중요: exercise_baselines의 is_hidden_from_home도 false로 업데이트 (부모 카드 표시)
      await _client
          .from('exercise_baselines')
          .update({
            'is_hidden_from_home': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', baselineId)
          .eq('user_id', userId);

      return true; // 복구 성공
    }

    // Step 3: 숨겨진 세트가 없으면 신규 (아무것도 하지 않음)
    return false; // 신규 운동
  }

  /// 특정 날짜의 세트 기록 삭제 (Soft Delete)
  /// 저장된 기록은 숨김 처리, 저장 안 된 기록은 완전 삭제
  Future<void> deleteWorkoutSetsByDate(
    String baselineId,
    DateTime date,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _ensureProfileExists();

    // [보안 검증] baseline_id가 현재 유저의 것인지 확인
    final baselineCheck = await _client
        .from('exercise_baselines')
        .select('id')
        .eq('id', baselineId)
        .eq('user_id', userId)
        .maybeSingle();

    if (baselineCheck == null) {
      throw Exception('해당 운동을 찾을 수 없거나 권한이 없습니다.');
    }

    // [중요] 날짜 포맷팅 (UTC 기준) - 절대 수정하지 않음
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    // Step 1: 조건(ID + 날짜)에 맞는 세트 존재 여부 확인
    final existingSets = await _client
        .from('workout_sets')
        .select('id, is_completed')
        .eq('baseline_id', baselineId)
        .gte('created_at', startStr)
        .lte('created_at', endStr);

    // Step 2: 세트가 있으면 (저장된 기록) - Soft Delete
    if ((existingSets as List).isNotEmpty) {
      // workout_sets: is_hidden = true로 업데이트
      await _client
          .from('workout_sets')
          .update({'is_hidden': true})
          .eq('baseline_id', baselineId)
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      // exercise_baselines: is_hidden_from_home = true로 업데이트 (홈 목록에서 제거)
      await _client
          .from('exercise_baselines')
          .update({
            'is_hidden_from_home': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', baselineId)
          .eq('user_id', userId);
    } else {
      // Step 3: 세트가 없으면 (저장 안 된 기록) - Hard Delete (기존 로직 유지)
      // 실제로는 이미 없으므로 delete는 필요 없지만, 기존 로직과의 호환성을 위해 유지
      // 실제로 삭제할 것이 없으므로 이 분기는 실행되지 않음
    }
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

  /// 운동 세션 정보 저장 (강도, 볼륨, 시간)
  /// [baselineId] 어떤 운동에 대한 평가인지 (개별 운동 단위)
  /// [date] 운동 날짜
  /// [difficulty] 강도 ('easy', 'normal', 'hard')
  /// [totalVolume] 총 볼륨 (Nullable)
  /// [durationMinutes] 운동 시간 분 (Nullable)
  Future<void> saveWorkoutSession({
    required String baselineId,
    required DateTime date,
    required String difficulty, // 'easy', 'normal', 'hard'
    double? totalVolume,
    int? durationMinutes,
  }) async {
    await _ensureProfileExists();
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    await _client.from('workout_sessions').insert({
      'user_id': userId,
      'baseline_id': baselineId,
      'workout_date': DateFormat('yyyy-MM-dd').format(date),
      'difficulty': difficulty,
      'total_volume': totalVolume,
      'duration_minutes': durationMinutes,
    });
  }

  /// 지난주(최근 7일) 운동 세션 조회
  /// 반환: WorkoutSession 리스트
  Future<List<WorkoutSession>> getLastWeekSessions() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final startDate = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);
    final endDate = DateFormat('yyyy-MM-dd').format(now);

    final response = await _client
        .from('workout_sessions')
        .select('*')
        .eq('user_id', userId)
        .gte('workout_date', startDate)
        .lte('workout_date', endDate)
        .order('workout_date', ascending: false);

    return (response as List)
        .map((json) => WorkoutSession.fromJson(json))
        .toList();
  }

  /// 특정 날짜의 평균 무게/횟수 조회
  /// [baselineId] 운동 ID
  /// [date] 날짜
  /// 반환: (평균 무게, 평균 횟수)
  Future<(double weight, int reps)> getLastWeekAverageSets(
    String baselineId,
    DateTime date,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    final response = await _client
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

  /// 특정 날짜의 '최고 중량 세트' 조회 (웜업 제외 목적)
  /// [baselineId] 운동 ID
  /// [date] 날짜
  /// 반환: (최고 무게, 그 세트의 횟수)
  Future<(double weight, int reps)> getLastWeekBestSet(
    String baselineId,
    DateTime date,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr = '${dateStr}T00:00:00Z';
    final endStr = '${dateStr}T23:59:59.999Z';

    final response = await _client
        .from('workout_sets')
        .select('weight, reps')
        .eq('baseline_id', baselineId)
        .eq('is_completed', true)
        .gte('created_at', startStr)
        .lte('created_at', endStr)
        .order('weight', ascending: false) // 무게 기준 내림차순 정렬
        .limit(1) // 1개만 가져옴 (가장 무거운 것)
        .maybeSingle(); // 없으면 null

    if (response == null) return (0.0, 0);

    final weight = (response['weight'] as num).toDouble();
    final reps = (response['reps'] as num).toInt();
    return (weight, reps);
  }

  /// 사용자 운동 목표 조회
  /// 반환: 'hypertrophy' 또는 'strength' (기본값: 'hypertrophy')
  Future<String> getUserGoal() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    try {
      final response = await _client
          .from('profiles')
          .select('workout_goal')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 'hypertrophy';
      
      final goal = response['workout_goal'] as String?;
      return goal ?? 'hypertrophy';
    } catch (e) {
      return 'hypertrophy'; // 기본값
    }
  }

  /// 주간 계획 일괄 저장
  Future<void> savePlannedWorkouts(List<PlannedWorkout> plans) async {
    await _ensureProfileExists();
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

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

    await _client.from('planned_workouts').insert(dataList);
  }

  /// ID 목록으로 운동 정보 일괄 조회
  /// [ids] baseline_id 리스트
  /// 반환: ExerciseBaseline 리스트
  Future<List<ExerciseBaseline>> getBaselinesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final response = await _client
        .from('exercise_baselines')
        .select()
        .inFilter('id', ids); // IN 쿼리 사용
        
    return (response as List).map((e) => ExerciseBaseline.fromJson(e)).toList();
  }

  /// 날짜 범위 내의 계획된 운동 조회
  /// [startDate] 시작 날짜
  /// [endDate] 종료 날짜
  /// 반환: PlannedWorkout 리스트
  Future<List<PlannedWorkout>> getPlannedWorkoutsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final response = await _client
        .from('planned_workouts')
        .select()
        .eq('user_id', userId)
        .gte('scheduled_date', startStr)
        .lte('scheduled_date', endStr);

    return (response as List)
        .map((json) => PlannedWorkout.fromJson(json))
        .toList();
  }

  /// 계획된 운동 완료 상태 토글
  Future<void> togglePlannedWorkoutCompletion(String id, bool isCompleted) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');
    
    await _client
        .from('planned_workouts')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동 삭제
  Future<void> deletePlannedWorkout(String id) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');
    
    await _client
        .from('planned_workouts')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 계획된 운동 수정 (무게, 횟수, 코멘트, 색상)
  Future<void> updatePlannedWorkout(
    String id, {
    required double targetWeight,
    required int targetReps,
    required String colorHex,
    String? aiComment,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');
    
    await _client
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

  /// 계획된 운동의 날짜(scheduled_date)만 수정
  ///
  /// - `planned_workouts.scheduled_date` 컬럼만 업데이트합니다.
  /// - 저장 형식은 `yyyy-MM-dd`로 통일합니다.
  Future<void> updatePlannedWorkoutDate(String id, DateTime newDate) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    final normalized = DateTime(newDate.year, newDate.month, newDate.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(normalized);

    await _client
        .from('planned_workouts')
        .update({'scheduled_date': dateStr})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// 날짜 범위 내의 계획된 운동 조회 (운동 이름 포함)
  /// 반환: (PlannedWorkout 리스트, baselineId -> exerciseName Map)
  Future<(List<PlannedWorkout>, Map<String, String>)> getPlannedWorkoutsByDateRangeWithNames(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    // 조인 쿼리: planned_workouts와 exercise_baselines 조인
    final response = await _client
        .from('planned_workouts')
        .select('*, exercise_baselines(exercise_name)')
        .eq('user_id', userId)
        .gte('scheduled_date', startStr)
        .lte('scheduled_date', endStr);

    final plannedWorkouts = <PlannedWorkout>[];
    final exerciseNameMap = <String, String>{};

    for (final row in response as List) {
      // PlannedWorkout 파싱 (exercise_baselines 필드 제거)
      final rowCopy = Map<String, dynamic>.from(row);
      final baselineData = rowCopy.remove('exercise_baselines');
      
      final plannedWorkout = PlannedWorkout.fromJson(rowCopy);
      plannedWorkouts.add(plannedWorkout);
      
      // exercise_baselines 조인 데이터에서 exercise_name 추출
      if (baselineData != null && baselineData is List && baselineData.isNotEmpty) {
        final exerciseName = baselineData[0]['exercise_name'] as String?;
        if (exerciseName != null) {
          exerciseNameMap[plannedWorkout.baselineId] = exerciseName;
        }
      }
    }

    return (plannedWorkouts, exerciseNameMap);
  }

  /// 계획된 운동을 완료 처리하고 WorkoutSet(실제 기록)으로 변환
  ///
  /// [inputs] 실제 수행 결과 입력값(무게/횟수/세트)
  /// [originalPlans] 완료 처리할 PlannedWorkout 원본 리스트 (plannedWorkoutId -> plan 매핑용)
  ///
  /// Process:
  /// 1. 상태 업데이트: is_completed=true, is_converted_to_log=true
  /// 2. inputs 기반으로 WorkoutSet 생성 (weight=actualWeight, reps=actualReps, sets=1..actualSets)
  /// 3. batchSaveWorkoutSets로 저장
  Future<void> completeAndConvertPlannedWorkouts(
    List<WorkoutCompletionInput> inputs,
    List<PlannedWorkout> originalPlans,
  ) async {
    if (inputs.isEmpty) return;
    
    await _ensureProfileExists();
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인 필요');

    // 1. 상태 업데이트: is_completed=true, is_converted_to_log=true
    final planIds = inputs.map((i) => i.plannedWorkoutId).toList();
    await _client
        .from('planned_workouts')
        .update({
          'is_completed': true,
          'is_converted_to_log': true,
        })
        .eq('user_id', userId)
        .inFilter('id', planIds);

    // 2. WorkoutSet 생성 (inputs 기준)
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
          sets: idx + 1, // 세트 번호 (1, 2, 3, ...)
          isCompleted: true,
          createdAt: plan.scheduledDate, // 계획된 날짜 사용
        ));
      }
    }

    // 3. WorkoutSet 일괄 저장
    if (workoutSets.isNotEmpty) {
      await batchSaveWorkoutSets(workoutSets);
    }
  }
}
