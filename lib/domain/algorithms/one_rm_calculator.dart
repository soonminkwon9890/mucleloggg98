/// 1RM 계산기 (Epley Formula 변형)
class OneRMCalculator {
  /// 1RM 추정
  /// 
  /// [weight] 사용한 무게 (kg)
  /// [reps] 수행한 횟수
  /// [rpe] RPE (Rate of Perceived Exertion) 1~10
  /// 
  /// 반환: 추정된 1RM 값
  static double calculate1RM(double weight, int reps, int rpe) {
    // RPE Factor 계산
    double rpeFactor;
    if (rpe < 5) {
      rpeFactor = 1.0; // 낮음
    } else if (rpe < 8) {
      rpeFactor = 1.05; // 보통
    } else {
      rpeFactor = 1.1; // 어려움
    }

    // Epley Formula 변형: 1RM = Weight × (1 + Reps/30) × RPE_Factor
    return weight * (1 + reps / 30) * rpeFactor;
  }

  /// RPE Factor 가져오기
  static double getRpeFactor(int rpe) {
    if (rpe < 5) {
      return 1.0;
    } else if (rpe < 8) {
      return 1.05;
    } else {
      return 1.1;
    }
  }

  /// RPE 레벨 문자열로 변환
  static String getRpeLevel(int rpe) {
    if (rpe < 5) {
      return 'LOW';
    } else if (rpe < 8) {
      return 'MEDIUM';
    } else {
      return 'HIGH';
    }
  }
}

