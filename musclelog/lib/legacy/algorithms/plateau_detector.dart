// Legacy: 추후 고도화 시 참고용
/*
import '../../data/models/workout_set.dart';

/// 정체기 감지 알고리즘
class PlateauDetector {
  /// 정체기 감지
  /// 
  /// [recentSets] 최근 세트 기록 리스트 (최신순)
  /// [thresholdDays] 정체기로 판단할 일수 (기본값: 14일)
  /// 
  /// 반환: 정체기 여부
  static bool detectPlateau(
    List<WorkoutSet> recentSets, {
    int thresholdDays = 14,
  }) {
    if (recentSets.length < 3) {
      return false; // 최소 3개 이상의 기록이 필요
    }

    // 최근 기록들만 필터링 (thresholdDays 이내)
    final now = DateTime.now();
    final thresholdDate = now.subtract(Duration(days: thresholdDays));

    final recentRecords = recentSets.where((set) {
      if (set.createdAt == null) return false;
      return set.createdAt!.isAfter(thresholdDate);
    }).toList();

    if (recentRecords.length < 3) {
      return false;
    }

    // 무게와 횟수가 모두 동일한지 확인
    final firstSet = recentRecords.first;
    final allSame = recentRecords.every((set) {
      return set.weight == firstSet.weight && set.reps == firstSet.reps;
    });

    return allSame;
  }

  /// 정체기 해결 방안 추천
  /// 
  /// [lastSet] 가장 최근 세트
  /// [strategy] 전략 ('deload' 또는 'overload')
  /// 
  /// 반환: 추천된 세트
  static WorkoutSet recommendSolution(
    WorkoutSet lastSet,
    String strategy,
  ) {
    if (strategy == 'deload') {
      // 디로딩: 무게 -10%
      return lastSet.copyWith(
        weight: lastSet.weight * 0.9,
        reps: lastSet.reps,
        isAiSuggested: true,
      );
    } else {
      // 강도 돌파: 무게 유지, 횟수 강제 증가
      return lastSet.copyWith(
        weight: lastSet.weight,
        reps: lastSet.reps + 2, // 횟수 2회 증가
        isAiSuggested: true,
      );
    }
  }
}
*/
