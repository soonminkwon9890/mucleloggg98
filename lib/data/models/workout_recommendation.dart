/// Gemini AI 응답 파싱용 모델 (루틴 추천 1건)
class WorkoutRecommendation {
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;
  final String reason;

  const WorkoutRecommendation({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.reason,
  });
}
