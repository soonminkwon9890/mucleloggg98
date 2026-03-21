import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../config/env_config.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/models/planned_workout_dto.dart';
import '../../data/models/workout_recommendation.dart';
import '../../data/models/workout_session.dart';

/// 점진적 과부하 원칙 기반 AI 루틴 추천 (Gemini Pro)
///
/// [Lookup Table 아키텍처]
/// - LLM에게 날짜 정보를 절대 전달하지 않음 (LLM은 날짜 처리에 취약)
/// - LLM은 오직 baselineId별 무게/횟수 추천만 반환
/// - Dart 코드가 원본 세션을 날짜별로 순회하며 targetDate = sourceDate + 7일 계산
/// - 결과: 다음 주 캘린더는 지난주의 100% 정확한 복제본 (+7일)
class AiCoachingService {
  static const String _systemInstruction = '''
너는 20년 경력의 보디빌딩 전문 헬스 트레이너야. 사용자의 이전 기록을 보고 '점진적 과부하(Progressive Overload)' 원칙에 따라 다음 운동 강도를 설계해줘.

[강도 설정 가이드라인]
1. 단순 증량 금지: 단순히 횟수만 1회 늘리는 것은 피한다.
2. 횟수 기반 증량 (Rep Range Rule): 만약 사용자의 이전 수행 횟수가 12회 이상이었다면, 무게를 2.5kg ~ 5kg 증량시키고, 대신 목표 횟수를 8~10회로 낮춰서 제안한다. (근비대 최적화)
3. 저반복 구간 (Strength Rule): 만약 수행 횟수가 6회 미만이었다면, 무게를 유지하거나 소폭 낮추고 횟수를 8회까지 올리도록 제안한다.
4. 세트 수: 기본적으로 이전 세트 수를 유지하되, 총 볼륨이 너무 낮다면 1세트를 추가한다.
5. 코칭 팁: 왜 이렇게 루틴을 짰는지 10자 내외의 짧은 이유를 함께 줘. (예: "무게를 올려 근성장을 노립니다.")

[필수 규칙 - 반드시 지켜야 함]
1. 모든 운동 포함: 입력에 포함된 모든 운동(baselineId)에 대해 반드시 추천을 출력해야 한다. 어떤 운동도 누락하지 마라.
2. baselineId 유지: 응답의 baselineId 필드는 입력에서 받은 값 그대로 출력해야 한다. 절대 변경하지 마라.

응답은 반드시 JSON 배열만 출력한다. 마크다운 코드 블록(```json)이나 설명 문구를 붙이지 마라.
스키마: [{"baselineId":"ID값","targetWeight":"85.0","targetReps":"8","targetSets":"3","reason":"코칭 팁"}]
''';

  /// Gemini API로 다음 주 루틴 추천 후 PlannedWorkoutDto 리스트로 반환
  ///
  /// [Lookup Table 방식]
  /// 1. baselineId별 고유 운동 목록 추출 (중복 제거)
  /// 2. LLM에게 날짜 없이 운동 목록만 전송
  /// 3. LLM 응답을 Map<baselineId, recommendation>으로 파싱
  /// 4. 원본 세션을 날짜별로 순회하며 targetDate = sourceDate + 7일 계산
  static Future<List<PlannedWorkoutDto>> getRecommendations({
    required List<WorkoutSession> lastWeekSessions,
    required String userGoal,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
  }) async {
    if (kDebugMode) {
      debugPrint('====== AI COACHING SERVICE DEBUG ======');
      debugPrint('[AI] Input sessions: ${lastWeekSessions.length}');
      debugPrint('[AI] BaselineMap keys (${baselineMap.length}): ${baselineMap.keys.toList()}');
      debugPrint('[AI] BestSetsMap EXACT KEYS (${bestSetsMap.length}):');
      for (final key in bestSetsMap.keys) {
        debugPrint('  KEY="$key" (length=${key.length})');
      }
      // [DEBUG] Show what composite keys would be built from sessions
      debugPrint('[AI] Sessions -> expected composite keys:');
      for (final s in lastWeekSessions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(s.workoutDate);
        final expectedKey = '${s.baselineId}_$dateStr';
        final found = bestSetsMap.containsKey(expectedKey);
        debugPrint('  session.workoutDate=${s.workoutDate} -> expectedKey="$expectedKey" (found=$found)');
      }
    }

    const apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY가 설정되지 않았습니다. --dart-define=GEMINI_API_KEY=... 로 빌드하세요.');
    }

    // [Step 1] baselineId별 고유 운동 목록 추출 (LLM용, 날짜 없음)
    final uniqueExercises = _extractUniqueExercises(
      lastWeekSessions: lastWeekSessions,
      baselineMap: baselineMap,
      bestSetsMap: bestSetsMap,
    );

    if (kDebugMode) {
      debugPrint('[AI] Step 1 - Unique exercises extracted: ${uniqueExercises.length}');
      for (final entry in uniqueExercises.entries) {
        debugPrint('  - ${entry.key}: ${entry.value.exerciseName}, ${entry.value.weight}kg x ${entry.value.reps}');
      }
    }

    if (uniqueExercises.isEmpty) {
      if (kDebugMode) debugPrint('[AI] ⚠️ uniqueExercises is EMPTY! Returning empty list.');
      return [];
    }

    // [Step 2] LLM 호출 (날짜 정보 없이 운동 목록만 전송)
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemInstruction),
    );

    final userPrompt = _buildUserPrompt(
      uniqueExercises: uniqueExercises,
      userGoal: userGoal,
    );

    if (kDebugMode) debugPrint('[AI] Step 2 - User prompt:\n$userPrompt');

    final response = await model.generateContent([Content.text(userPrompt)]);
    final text = response.text;

    if (kDebugMode) debugPrint('[AI] Step 2 - Raw LLM Response:\n$text');

    if (text == null || text.isEmpty) {
      throw Exception('Gemini API 응답이 비어있습니다.');
    }

    // [Step 3] LLM 응답을 Map<baselineId, recommendation>으로 파싱
    final llmRecommendations = _parseLlmResponse(text, uniqueExercises);

    if (kDebugMode) {
      debugPrint('[AI] Step 3 - Parsed recommendations: ${llmRecommendations.length}');
      for (final entry in llmRecommendations.entries) {
        debugPrint('  - ${entry.key}: ${entry.value.weight}kg x ${entry.value.reps}');
      }
    }

    // [Step 4] 원본 세션을 날짜별로 순회하며 계획 생성
    final plans = _reconstructCalendar(
      lastWeekSessions: lastWeekSessions,
      baselineMap: baselineMap,
      bestSetsMap: bestSetsMap,
      llmRecommendations: llmRecommendations,
    );

    if (kDebugMode) {
      debugPrint('[AI] Step 4 - Final plans generated: ${plans.length}');
      debugPrint('====== END AI COACHING SERVICE DEBUG ======');
    }

    return plans;
  }

  /// [Step 1] baselineId별 고유 운동 목록 추출
  /// 같은 운동을 주중 여러 번 해도 LLM에게는 한 번만 전송
  /// [bestSetsMap]은 composite key 또는 baselineId key 모두 지원
  static Map<String, _UniqueExercise> _extractUniqueExercises({
    required List<WorkoutSession> lastWeekSessions,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
  }) {
    final uniqueExercises = <String, _UniqueExercise>{};

    if (kDebugMode) debugPrint('[_extractUniqueExercises] Processing ${lastWeekSessions.length} sessions');

    for (final session in lastWeekSessions) {
      final baselineId = session.baselineId;

      // 이미 처리된 baselineId는 스킵 (중복 제거)
      if (uniqueExercises.containsKey(baselineId)) {
        if (kDebugMode) debugPrint('  [SKIP] baselineId=$baselineId already processed');
        continue;
      }

      final baseline = baselineMap[baselineId];

      // [ROBUST FIX] Try composite key first, fallback to baselineId
      final dateStr = DateFormat('yyyy-MM-dd').format(session.workoutDate);
      final compositeKey = '${baselineId}_$dateStr';
      final bestSet = bestSetsMap[compositeKey] ?? bestSetsMap[baselineId];

      if (kDebugMode) {
        debugPrint('  [CHECK] baselineId=$baselineId');
        debugPrint('    compositeKey=$compositeKey, fallbackKey=$baselineId');
        debugPrint('    baseline=${baseline?.exerciseName ?? "NULL"}');
        debugPrint('    bestSet=$bestSet (found via ${bestSetsMap.containsKey(compositeKey) ? "composite" : "fallback"})');
      }

      if (baseline == null) {
        if (kDebugMode) debugPrint('    ⚠️ SKIPPED: baseline is NULL');
        continue;
      }
      if (bestSet == null) {
        if (kDebugMode) debugPrint('    ⚠️ SKIPPED: bestSet is NULL for both $compositeKey and $baselineId');
        continue;
      }

      final (weight, reps) = bestSet;
      // 0kg/0회 운동은 제외
      if (weight <= 0 && reps <= 0) {
        if (kDebugMode) debugPrint('    ⚠️ SKIPPED: weight=$weight, reps=$reps (zero data)');
        continue;
      }

      if (kDebugMode) debugPrint('    ✓ ADDED: ${baseline.exerciseName}, ${weight}kg x $reps');
      uniqueExercises[baselineId] = _UniqueExercise(
        baselineId: baselineId,
        exerciseName: baseline.exerciseName,
        weight: weight,
        reps: reps,
        difficulty: session.difficulty,
      );
    }

    return uniqueExercises;
  }

  /// [Step 2] 사용자 프롬프트 생성 (날짜 없음!)
  static String _buildUserPrompt({
    required Map<String, _UniqueExercise> uniqueExercises,
    required String userGoal,
  }) {
    final goalText = userGoal == 'hypertrophy' ? '근비대' : '근력';
    final lines = <String>[];

    for (final exercise in uniqueExercises.values) {
      lines.add(
        'baselineId=${exercise.baselineId}, '
        '운동명=${exercise.exerciseName}, '
        '${exercise.weight}kg, ${exercise.reps}회, 강도=${exercise.difficulty}',
      );
    }

    return '''사용자 목표: $goalText
지난주 운동 기록 (baselineId, 운동명, 무게, 횟수, 강도):
${lines.join('\n')}

[중요] 위 목록의 모든 운동(baselineId)에 대해 빠짐없이 다음 주 추천을 출력해야 한다.
baselineId는 입력 그대로 유지하라.
JSON 배열만 출력해줘.''';
  }

  /// [Step 3] LLM 응답을 Map<baselineId, recommendation>으로 파싱
  static Map<String, WorkoutRecommendation> _parseLlmResponse(
    String text,
    Map<String, _UniqueExercise> uniqueExercises,
  ) {
    final llmRecommendations = <String, WorkoutRecommendation>{};

    try {
      final cleaned = _cleanJsonResponse(text);
      final jsonData = jsonDecode(cleaned);

      if (jsonData is! List) {
        // JSON 파싱 실패 시 빈 맵 반환 (폴백 로직이 처리)
        return llmRecommendations;
      }

      for (final item in jsonData) {
        if (item is! Map<String, dynamic>) continue;

        final baselineId = item['baselineId'] as String?;
        if (baselineId == null || baselineId.isEmpty) continue;

        final targetWeight = (item['targetWeight'] is num)
            ? (item['targetWeight'] as num).toDouble()
            : double.tryParse(item['targetWeight']?.toString() ?? '');

        final targetReps = (item['targetReps'] is num)
            ? (item['targetReps'] as num).toInt()
            : int.tryParse(item['targetReps']?.toString() ?? '');

        final targetSetsRaw = (item['targetSets'] is num)
            ? (item['targetSets'] as num).toInt()
            : int.tryParse(item['targetSets']?.toString() ?? '');

        final reason = item['reason'] as String? ?? '';

        if (targetWeight == null || targetReps == null) continue;

        final targetSets = (targetSetsRaw != null && targetSetsRaw >= 1) ? targetSetsRaw : 3;

        llmRecommendations[baselineId] = WorkoutRecommendation(
          baselineId: baselineId,
          weight: targetWeight,
          reps: targetReps,
          sets: targetSets,
          reason: reason,
        );
      }
    } catch (e) {
      // 파싱 실패 시 빈 맵 반환 (폴백 로직이 처리)
    }

    return llmRecommendations;
  }

  /// [Step 4] 원본 세션을 날짜별로 순회하며 캘린더 재구성
  ///
  /// [핵심 보장]
  /// - 다음 주 캘린더는 지난주의 100% 정확한 복제본
  /// - 각 세션의 targetDate = sourceDate + 7일
  /// - AI 추천이 있으면 무게/횟수만 교체, 없으면 원본 그대로 복사
  /// [bestSetsMap]은 composite key 사용: "${baselineId}_${YYYY-MM-DD}"
  static List<PlannedWorkoutDto> _reconstructCalendar({
    required List<WorkoutSession> lastWeekSessions,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
    required Map<String, WorkoutRecommendation> llmRecommendations,
  }) {
    final plans = <PlannedWorkoutDto>[];

    if (kDebugMode) {
      debugPrint('[_reconstructCalendar] Processing ${lastWeekSessions.length} sessions');
      debugPrint('[_reconstructCalendar] llmRecommendations keys: ${llmRecommendations.keys.toList()}');
    }

    // 날짜순 정렬 (일관된 순서 보장)
    final sortedSessions = List<WorkoutSession>.from(lastWeekSessions)
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

    // 같은 날 같은 운동 중복 방지용 (날짜+baselineId)
    final processedKeys = <String>{};

    for (final session in sortedSessions) {
      final baselineId = session.baselineId;
      final baseline = baselineMap[baselineId];

      // [ROBUST FIX] Try composite key first, fallback to baselineId
      final dateStr = DateFormat('yyyy-MM-dd').format(session.workoutDate);
      final compositeKey = '${baselineId}_$dateStr';
      final bestSet = bestSetsMap[compositeKey] ?? bestSetsMap[baselineId];

      if (kDebugMode) {
        debugPrint('[_reconstructCalendar] Session: baselineId=$baselineId');
        debugPrint('  compositeKey=$compositeKey, fallbackKey=$baselineId');
        debugPrint('  baseline=${baseline?.exerciseName ?? "NULL"}');
        debugPrint('  bestSet=$bestSet (found via ${bestSetsMap.containsKey(compositeKey) ? "composite" : "fallback"})');
      }

      if (baseline == null) {
        if (kDebugMode) debugPrint('  ⚠️ SKIPPED: baseline is NULL');
        continue;
      }
      if (bestSet == null) {
        if (kDebugMode) debugPrint('  ⚠️ SKIPPED: bestSet is NULL for both keys');
        continue;
      }

      final (currentWeight, currentReps) = bestSet;
      // 0kg/0회 운동은 제외
      if (currentWeight <= 0 && currentReps <= 0) {
        if (kDebugMode) debugPrint('  ⚠️ SKIPPED: zero weight/reps');
        continue;
      }

      // 같은 날 같은 운동 중복 방지
      final uniqueKey = '$baselineId|$dateStr';
      if (processedKeys.contains(uniqueKey)) {
        if (kDebugMode) debugPrint('  ⚠️ SKIPPED: duplicate key $uniqueKey');
        continue;
      }
      processedKeys.add(uniqueKey);

      // [핵심] targetDate = sourceDate + 7일 (100% Dart 계산, LLM 무관)
      final sourceDate = DateTime(
        session.workoutDate.year,
        session.workoutDate.month,
        session.workoutDate.day,
      );
      final targetDate = sourceDate.add(const Duration(days: 7));

      // LLM 추천 조회
      final rec = llmRecommendations[baselineId];
      if (kDebugMode) debugPrint('  LLM rec for $baselineId: ${rec != null ? "${rec.weight}kg x ${rec.reps}" : "NULL (will use fallback)"}');

      if (rec != null) {
        // AI 추천 있음 → AI 권장 무게/횟수 사용
        plans.add(PlannedWorkoutDto(
          baselineId: baseline.id,
          exerciseName: baseline.exerciseName,
          currentWeight: currentWeight,
          targetWeight: rec.weight,
          currentReps: currentReps,
          targetReps: rec.reps,
          targetSets: rec.sets,
          aiComment: rec.reason,
          scheduledDate: targetDate,
        ));
        if (kDebugMode) debugPrint('  ✓ ADDED with AI: ${baseline.exerciseName} -> ${rec.weight}kg x ${rec.reps}');
      } else {
        // [폴백] AI가 누락한 운동 → 원본 무게/횟수 그대로 복사
        plans.add(PlannedWorkoutDto(
          baselineId: baseline.id,
          exerciseName: baseline.exerciseName,
          currentWeight: currentWeight,
          targetWeight: currentWeight, // 무게 유지
          currentReps: currentReps,
          targetReps: currentReps, // 횟수 유지
          targetSets: 3,
          aiComment: '유지',
          scheduledDate: targetDate,
        ));
        if (kDebugMode) debugPrint('  ✓ ADDED with fallback: ${baseline.exerciseName} -> ${currentWeight}kg x $currentReps');
      }
    }

    if (kDebugMode) debugPrint('[_reconstructCalendar] Total plans created: ${plans.length}');
    return plans;
  }

  static String _cleanJsonResponse(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(cleaned.indexOf('```') + 3);
      if (cleaned.startsWith('json')) {
        cleaned = cleaned.substring(4).trimLeft();
      } else if (cleaned.startsWith('\n')) {
        cleaned = cleaned.substring(1);
      }
      final lastIndex = cleaned.lastIndexOf('```');
      if (lastIndex != -1) {
        cleaned = cleaned.substring(0, lastIndex).trimRight();
      }
    }
    return cleaned.trim();
  }

  /// 소스 세션 날짜 기준, 다음 주 동일 요일 날짜를 계산합니다.
  static DateTime calculateNextSessionDate(DateTime sourceDate) {
    final normalized = DateTime(sourceDate.year, sourceDate.month, sourceDate.day);
    return normalized.add(const Duration(days: 7));
  }
}

/// LLM에 전송할 고유 운동 정보 (날짜 없음)
class _UniqueExercise {
  final String baselineId;
  final String exerciseName;
  final double weight;
  final int reps;
  final String difficulty;

  const _UniqueExercise({
    required this.baselineId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.difficulty,
  });
}
