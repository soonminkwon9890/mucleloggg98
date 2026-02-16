import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env_config.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/models/planned_workout_dto.dart';
import '../../data/models/workout_recommendation.dart';
import '../../data/models/workout_session.dart';

/// 점진적 과부하 원칙 기반 AI 루틴 추천 (Gemini Pro)
class AiCoachingService {
  static const String _systemInstruction = '''
너는 20년 경력의 보디빌딩 전문 헬스 트레이너야. 사용자의 이전 기록을 보고 '점진적 과부하(Progressive Overload)' 원칙에 따라 다음 운동 강도를 설계해줘.

[강도 설정 가이드라인]
1. 단순 증량 금지: 단순히 횟수만 1회 늘리는 것은 피한다.
2. 횟수 기반 증량 (Rep Range Rule): 만약 사용자의 이전 수행 횟수가 12회 이상이었다면, 무게를 2.5kg ~ 5kg 증량시키고, 대신 목표 횟수를 8~10회로 낮춰서 제안한다. (근비대 최적화)
3. 저반복 구간 (Strength Rule): 만약 수행 횟수가 6회 미만이었다면, 무게를 유지하거나 소폭 낮추고 횟수를 8회까지 올리도록 제안한다.
4. 세트 수: 기본적으로 이전 세트 수를 유지하되, 총 볼륨이 너무 낮다면 1세트를 추가한다.
5. 코칭 팁: 왜 이렇게 루틴을 짰는지 10자 내외의 짧은 이유를 함께 줘. (예: "무게를 올려 근성장을 노립니다.")
6. 운동 명칭 엄수: 응답의 exerciseName 필드는 반드시 사용자가 입력한 텍스트(Input)에 있는 운동 이름 그대로 사용해야 한다. 임의로 번역하거나 단어를 추가/삭제하지 마라.

응답은 반드시 JSON 배열만 출력한다. 마크다운 코드 블록(```json)이나 설명 문구를 붙이지 마라.
스키마: [{"exerciseName":"운동명","weight":"85.0","reps":"8","sets":"3","reason":"코칭 팁"}]
''';

  /// Gemini API로 다음 주 루틴 추천 후 PlannedWorkoutDto 리스트로 반환
  static Future<List<PlannedWorkoutDto>> getRecommendations({
    required List<WorkoutSession> lastWeekSessions,
    required String userGoal,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
  }) async {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY가 설정되지 않았습니다.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemInstruction),
    );

    final userPrompt = _buildUserPrompt(
      lastWeekSessions: lastWeekSessions,
      userGoal: userGoal,
      baselineMap: baselineMap,
      bestSetsMap: bestSetsMap,
    );

    final response = await model.generateContent([Content.text(userPrompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini API 응답이 비어있습니다.');
    }

    final cleaned = _cleanJsonResponse(text);
    final jsonData = jsonDecode(cleaned);
    if (jsonData is! List) {
      throw Exception('Gemini 응답이 JSON 배열이 아닙니다.');
    }

    final recommendations = <WorkoutRecommendation>[];
    for (final item in jsonData) {
      if (item is! Map<String, dynamic>) continue;
      final rec = _parseRecommendationItem(item);
      if (rec != null) recommendations.add(rec);
    }

    if (recommendations.isEmpty) {
      throw Exception('파싱된 추천이 없습니다.');
    }

    return _mergeToPlannedWorkoutDto(
      recommendations: recommendations,
      baselineMap: baselineMap,
      bestSetsMap: bestSetsMap,
      lastWeekSessions: lastWeekSessions,
    );
  }

  static String _buildUserPrompt({
    required List<WorkoutSession> lastWeekSessions,
    required String userGoal,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
  }) {
    final goalText = userGoal == 'hypertrophy' ? '근비대' : '근력';
    final lines = <String>[];
    final sessionsByBaseline = <String, List<WorkoutSession>>{};
    for (final s in lastWeekSessions) {
      sessionsByBaseline.putIfAbsent(s.baselineId, () => []).add(s);
    }
    for (final entry in sessionsByBaseline.entries) {
      final baseline = baselineMap[entry.key];
      final bestSet = bestSetsMap[entry.key];
      if (baseline == null || bestSet == null) continue;
      entry.value.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
      final latest = entry.value.first;
      final (w, r) = bestSet;
      // [수정] 0kg/0회 운동은 AI 프롬프트에서 제외 (기록 없는 운동 추천 방지)
      if (w <= 0 && r <= 0) continue;
      lines.add(
        '${baseline.exerciseName}: $w kg, $r 회, 3세트, 강도=${latest.difficulty}',
      );
    }
    return '''사용자 목표: $goalText
지난주 기록 (운동명, 무게, 횟수, 세트, 강도):
${lines.join('\n')}

위 목록과 동일한 운동명(exerciseName)을 유지한 채, 다음 주 루틴을 JSON 배열만 출력해줘.''';
  }

  static WorkoutRecommendation? _parseRecommendationItem(Map<String, dynamic> item) {
    final name = item['exerciseName'] as String?;
    if (name == null || name.isEmpty) return null;
    final weight = (item['weight'] is num)
        ? (item['weight'] as num).toDouble()
        : double.tryParse(item['weight']?.toString() ?? '');
    final reps = (item['reps'] is num)
        ? (item['reps'] as num).toInt()
        : int.tryParse(item['reps']?.toString() ?? '');
    final setsRaw = (item['sets'] is num)
        ? (item['sets'] as num).toInt()
        : int.tryParse(item['sets']?.toString() ?? '');
    final reason = item['reason'] as String? ?? '';
    if (weight == null || reps == null) return null;
    final sets = (setsRaw != null && setsRaw >= 1) ? setsRaw : 3;
    return WorkoutRecommendation(
      exerciseName: name.trim(),
      weight: weight,
      reps: reps,
      sets: sets,
      reason: reason,
    );
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

  static List<PlannedWorkoutDto> _mergeToPlannedWorkoutDto({
    required List<WorkoutRecommendation> recommendations,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
    required List<WorkoutSession> lastWeekSessions,
  }) {
    final sessionsByBaseline = <String, List<WorkoutSession>>{};
    for (final s in lastWeekSessions) {
      sessionsByBaseline.putIfAbsent(s.baselineId, () => []).add(s);
    }
    for (final key in sessionsByBaseline.keys) {
      sessionsByBaseline[key]!.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
    }

    final nameToBaseline = <String, ExerciseBaseline>{};
    for (final b in baselineMap.values) {
      nameToBaseline[b.exerciseName] = b;
    }

    final plans = <PlannedWorkoutDto>[];
    for (final rec in recommendations) {
      final baseline = nameToBaseline[rec.exerciseName];
      if (baseline == null) continue;
      final bestSet = bestSetsMap[baseline.id];
      if (bestSet == null) continue;
      final sessions = sessionsByBaseline[baseline.id];
      if (sessions == null || sessions.isEmpty) continue;
      final nextWeekDate = calculateNextSessionDate(sessions.first.workoutDate);
      final (currentWeight, currentReps) = bestSet;
      // [수정] 0kg/0회 운동은 최종 계획에서 제외 (기록 없는 운동 추천 방지)
      if (currentWeight <= 0 || currentReps <= 0) continue;
      plans.add(PlannedWorkoutDto(
        baselineId: baseline.id,
        exerciseName: baseline.exerciseName,
        currentWeight: currentWeight,
        targetWeight: rec.weight,
        currentReps: currentReps,
        targetReps: rec.reps,
        targetSets: rec.sets,
        aiComment: rec.reason,
        scheduledDate: nextWeekDate,
      ));
    }
    return plans;
  }

  /// 소스 세션 날짜 기준, 다음 주 동일 요일 날짜를 계산합니다.
  ///
  /// - 로직: `nextDate = lastSessionDate + 7 days`
  /// - 주의: 시간(Hour/Min/Sec)은 제거하여 `DateTime(y,m,d)`(00:00:00) 형태로 반환합니다.
  static DateTime calculateNextSessionDate(DateTime sourceDate) {
    final normalized = DateTime(sourceDate.year, sourceDate.month, sourceDate.day);
    return normalized.add(const Duration(days: 7));
  }
}
