// Legacy: 추후 고도화 시 참고용
/* 
import '../../data/models/workout_set.dart';
import 'one_rm_calculator.dart';

/// 점진적 과부하 추천 로직
class OverloadManager {
  /// 다음 세트 추천
  ///
  /// [lastSet] 가장 최근 수행한 세트
  ///
  /// 반환: 추천된 다음 세트
  static WorkoutSet recommendNextSet(WorkoutSet lastSet) {
    final current1RM = OneRMCalculator.calculate1RM(
      lastSet.weight,
      lastSet.reps,
      lastSet.rpe ?? 7, // 기본값 7
    );

    final rpe = lastSet.rpe ?? 7;

    // 근비대를 위한 최적 범위: 1RM의 70-80%
    const double minHypertrophyPercentage = 0.70;
    const double maxHypertrophyPercentage = 0.80;

    // 현재 무게가 1RM 대비 몇 %인지 계산
    final currentPercentage = lastSet.weight / current1RM;

    // 목표 무게 범위 계산
    final minTargetWeight = current1RM * minHypertrophyPercentage;
    final maxTargetWeight = current1RM * maxHypertrophyPercentage;
    final optimalTargetWeight = current1RM * 0.75; // 중간값 (75%)

    if (rpe < 7) {
      // 너무 쉬웠음 -> 무게 증량
      // 현재 무게가 목표 범위보다 낮으면 더 큰 폭으로 증가
      double weightIncrease;
      if (currentPercentage < minHypertrophyPercentage) {
        // 목표 범위보다 낮으면 최소 목표 무게까지 증가
        weightIncrease = (minTargetWeight - lastSet.weight).clamp(2.5, 10.0);
      } else {
        // 목표 범위 내에 있으면 표준 증가량 (2.5kg)
        weightIncrease = 2.5;
      }

      final newWeight = (lastSet.weight + weightIncrease).clamp(
        minTargetWeight,
        maxTargetWeight,
      );

      return lastSet.copyWith(
        weight: newWeight,
        reps: lastSet.reps,
        estimated1rm: current1RM,
        isAiSuggested: true,
      );
    } else if (rpe > 9) {
      // 너무 어려웠음 -> 무게 유지 또는 감소
      // 현재 무게가 목표 범위를 초과하면 감소
      double newWeight;
      if (currentPercentage > maxHypertrophyPercentage) {
        // 목표 범위를 초과하면 최대 목표 무게로 감소
        newWeight = maxTargetWeight;
      } else {
        // 목표 범위 내에 있으면 무게 유지
        newWeight = lastSet.weight;
      }

      return lastSet.copyWith(
        weight: newWeight,
        reps: lastSet.reps,
        estimated1rm: current1RM,
        isAiSuggested: true,
      );
    } else {
      // 적당함(RPE 7-9) -> 점진적 과부하
      // 현재 무게가 최적 범위보다 낮으면 무게 증가, 높으면 횟수 증가
      double newWeight;
      int newReps;

      if (currentPercentage < 0.72) {
        // 최적 범위보다 낮으면 무게를 소폭 증가 (1.25kg)
        newWeight = (lastSet.weight + 1.25).clamp(
          minTargetWeight,
          optimalTargetWeight,
        );
        newReps = lastSet.reps;
      } else if (currentPercentage > 0.78) {
        // 최적 범위보다 높으면 무게 유지, 횟수 증가
        newWeight = lastSet.weight;
        newReps = lastSet.reps + 1;
      } else {
        // 최적 범위 내에 있으면 무게 소폭 증가 또는 횟수 증가
        // RPE가 7-8이면 무게 증가, 8-9면 횟수 증가
        if (rpe < 8) {
          newWeight = (lastSet.weight + 1.25).clamp(
            lastSet.weight,
            optimalTargetWeight,
          );
          newReps = lastSet.reps;
        } else {
          newWeight = lastSet.weight;
          newReps = lastSet.reps + 1;
        }
      }

      return lastSet.copyWith(
        weight: newWeight,
        reps: newReps,
        estimated1rm: current1RM,
        isAiSuggested: true,
      );
    }
  }

  /// 목표 강도에 맞는 무게/횟수 추천
  ///
  /// [lastSet] 가장 최근 수행한 세트
  /// [targetPercentage] 목표 강도 (1RM의 몇 %, 예: 0.75 = 75%)
  ///
  /// 반환: 추천된 세트
  static WorkoutSet recommendByTargetPercentage(
    WorkoutSet lastSet,
    double targetPercentage,
  ) {
    final current1RM = OneRMCalculator.calculate1RM(
      lastSet.weight,
      lastSet.reps,
      lastSet.rpe ?? 7,
    );

    final targetWeight = current1RM * targetPercentage;

    // 목표 무게에 맞는 횟수 추정 (역산)
    // 1RM = Weight × (1 + Reps/30) × RPE_Factor
    // Reps = ((1RM / (Weight × RPE_Factor)) - 1) × 30
    final rpeFactor = OneRMCalculator.getRpeFactor(lastSet.rpe ?? 7);
    final estimatedReps = ((current1RM / (targetWeight * rpeFactor)) - 1) * 30;

    return lastSet.copyWith(
      weight: targetWeight,
      reps: estimatedReps.round().clamp(1, 30),
      isAiSuggested: true,
    );
  }
}
*/
