import 'package:flutter/foundation.dart';

import '../../core/services/ai_coaching_service.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/models/planned_workout_dto.dart';

/// 운동 추천 서비스
/// 상세 분석 페이지의 무게 추천 로직을 재사용 가능한 형태로 분리
class WorkoutRecommendationService {
  /// 다음 운동 무게와 횟수를 추천합니다.
  /// 
  /// [intensity] '쉬움', '보통', '어려움' 또는 'easy', 'normal', 'hard'
  /// [currentWeight] 현재 사용한 무게 (kg)
  /// [currentReps] 현재 수행한 횟수
  /// 반환: (추천 무게, 추천 횟수)
  static (double weight, int reps) calculateNextWeight({
    required String intensity,
    required double currentWeight,
    required int currentReps,
  }) {
    // 한국어와 영어 모두 지원
    final normalizedIntensity = _normalizeIntensity(intensity);
    
    switch (normalizedIntensity) {
      case 'hard':
      case '어려움':
        return (currentWeight, currentReps); // 무게 유지
      case 'normal':
      case '보통':
        return (currentWeight + 2.5, currentReps); // 무게 증가
      case 'easy':
      case '쉬움':
      case '낮음':
        return (currentWeight + 5.0, currentReps); // 무게 증가
      default:
        return (currentWeight, currentReps);
    }
  }

  /// 1RM 계산 (Epley 공식)
  /// 단순 Epley 공식: 1RM = 무게 * (1 + (0.0333 * 횟수))
  static double calculateOneRepMax(double weight, int reps) {
    return weight * (1 + (0.0333 * reps));
  }

  /// 추천 텍스트 생성
  /// 
  /// [intensity] 강도 ('쉬움', '보통', '어려움' 등)
  /// [weight] 추천 무게
  /// [reps] 추천 횟수
  /// 반환: 추천 메시지 텍스트
  static String getRecommendationText({
    required String intensity,
    required double weight,
    required int reps,
  }) {
    final normalizedIntensity = _normalizeIntensity(intensity);
    String description;
    
    switch (normalizedIntensity) {
      case 'hard':
      case '어려움':
        description = '무게 유지';
        break;
      case 'normal':
      case '보통':
        description = '무게 증가';
        break;
      case 'easy':
      case '쉬움':
      case '낮음':
        description = '무게 증가';
        break;
      default:
        description = '';
    }
    
    return '다음 운동: ${weight}kg × $reps회 ($description)';
  }

  /// 강도 문자열을 정규화합니다.
  /// 한국어와 영어 모두 지원
  static String _normalizeIntensity(String intensity) {
    final lower = intensity.toLowerCase().trim();
    
    // 한국어 매핑
    if (lower == '쉬움' || lower == '낮음' || lower == 'easy') {
      return 'easy';
    } else if (lower == '보통' || lower == 'normal') {
      return 'normal';
    } else if (lower == '어려움' || lower == 'hard') {
      return 'hard';
    }
    
    return lower; // 기본값 반환
  }

  /// 주간 운동 계획 생성 (AI 전용, Fail Fast)
  ///
  /// [lastWeekSessions] 지난주(최근 7일) 운동 세션 리스트
  /// [userGoal] 사용자 목표 ('hypertrophy' 또는 'strength')
  /// [baselineMap] baselineId -> ExerciseBaseline 매핑 (운동명 조회용)
  /// [bestSetsMap] baselineId -> (최고 무게, 그 세트의 횟수) 매핑
  /// 반환: 생성된 주간 계획 리스트. 실패 시 예외를 rethrow하여 UI가 SnackBar로 표시할 수 있게 함.
  static Future<List<PlannedWorkoutDto>> generateWeeklyPlan({
    required List<WorkoutSession> lastWeekSessions,
    required String userGoal,
    required Map<String, ExerciseBaseline> baselineMap,
    required Map<String, (double weight, int reps)> bestSetsMap,
  }) async {
    debugPrint('[WorkoutRecommendationService] AI Start');
    try {
      final plans = await AiCoachingService.getRecommendations(
        lastWeekSessions: lastWeekSessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: bestSetsMap,
      );
      if (plans.isNotEmpty) return plans;
      return [];
    } catch (e, st) {
      debugPrint('[WorkoutRecommendationService] AI failed: $e\n$st');
      rethrow;
    }
  }
}

