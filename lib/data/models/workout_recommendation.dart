/// Gemini AI 응답 파싱용 모델 (루틴 추천 1건)
///
/// [Lookup Table 아키텍처]
/// - LLM은 날짜를 절대 다루지 않음
/// - baselineId별로 무게/횟수 추천만 반환
/// - 날짜 계산은 100% Dart 코드에서 처리 (sourceDate + 7일)
class WorkoutRecommendation {
  /// 운동 식별자 (Lookup 키로 사용)
  final String? baselineId;

  /// 추천 무게
  final double weight;

  /// 추천 횟수
  final int reps;

  /// 추천 세트 수
  final int sets;

  /// 코칭 팁
  final String reason;

  const WorkoutRecommendation({
    this.baselineId,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.reason,
  });
}
