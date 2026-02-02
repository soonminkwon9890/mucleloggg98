class WorkoutCompletionInput {
  final String plannedWorkoutId;
  final double actualWeight;
  final int actualReps;
  final int actualSets;

  const WorkoutCompletionInput({
    required this.plannedWorkoutId,
    required this.actualWeight,
    required this.actualReps,
    required this.actualSets,
  });

  Map<String, dynamic> toJson() => {
        'plannedWorkoutId': plannedWorkoutId,
        'actualWeight': actualWeight,
        'actualReps': actualReps,
        'actualSets': actualSets,
      };

  factory WorkoutCompletionInput.fromJson(Map<String, dynamic> json) {
    return WorkoutCompletionInput(
      plannedWorkoutId: json['plannedWorkoutId'] as String,
      actualWeight: (json['actualWeight'] as num).toDouble(),
      actualReps: (json['actualReps'] as num).toInt(),
      actualSets: (json['actualSets'] as num).toInt(),
    );
  }
}

