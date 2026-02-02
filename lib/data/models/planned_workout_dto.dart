/// 주간 루틴 생성 결과 DTO (UI 표시용)
class PlannedWorkoutDto {
  final String baselineId;
  final String exerciseName;
  final double currentWeight;
  final double targetWeight;
  final int currentReps;
  final int targetReps;
  /// 목표 세트 수 (기본 3). AI 추천 또는 규칙 기반에서 설정.
  final int targetSets;
  final String aiComment;
  final DateTime scheduledDate;

  PlannedWorkoutDto({
    required this.baselineId,
    required this.exerciseName,
    required this.currentWeight,
    required this.targetWeight,
    required this.currentReps,
    required this.targetReps,
    this.targetSets = 3,
    required this.aiComment,
    required this.scheduledDate,
  });

  /// 불변성 유지하며 날짜 등 필드만 변경 (배치 스케줄링용)
  PlannedWorkoutDto copyWith({
    String? baselineId,
    String? exerciseName,
    double? currentWeight,
    double? targetWeight,
    int? currentReps,
    int? targetReps,
    int? targetSets,
    String? aiComment,
    DateTime? scheduledDate,
  }) {
    return PlannedWorkoutDto(
      baselineId: baselineId ?? this.baselineId,
      exerciseName: exerciseName ?? this.exerciseName,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      currentReps: currentReps ?? this.currentReps,
      targetReps: targetReps ?? this.targetReps,
      targetSets: targetSets ?? this.targetSets,
      aiComment: aiComment ?? this.aiComment,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }
}

