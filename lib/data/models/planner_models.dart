import 'package:flutter/foundation.dart';

/// AI 주간 루틴 플래너의 개별 운동 카드 (불변 데이터 모델)
///
/// [key] : 드래그 앤 드롭 안정성을 위한 고유 Flutter Key.
///         UniqueKey() 로 생성하여 리스트 내 카드를 안전하게 식별합니다.
///         copyWith 시 명시하지 않으면 원본 key 가 유지됩니다.
@immutable
class PlannerExerciseCard {
  final Key key;
  final String baselineId;
  final String exerciseName;
  final double targetWeight;
  final int targetReps;
  final int targetSets;
  final String aiComment;

  /// AI 가 제안한 카드인 경우 true → 별 아이콘 + "AI 제안" 태그 표시
  final bool isAiProposed;

  const PlannerExerciseCard({
    required this.key,
    required this.baselineId,
    required this.exerciseName,
    required this.targetWeight,
    required this.targetReps,
    required this.targetSets,
    this.aiComment = '',
    this.isAiProposed = false,
  });

  PlannerExerciseCard copyWith({
    Key? key,
    String? baselineId,
    String? exerciseName,
    double? targetWeight,
    int? targetReps,
    int? targetSets,
    String? aiComment,
    bool? isAiProposed,
  }) {
    return PlannerExerciseCard(
      key: key ?? this.key,
      baselineId: baselineId ?? this.baselineId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetWeight: targetWeight ?? this.targetWeight,
      targetReps: targetReps ?? this.targetReps,
      targetSets: targetSets ?? this.targetSets,
      aiComment: aiComment ?? this.aiComment,
      isAiProposed: isAiProposed ?? this.isAiProposed,
    );
  }
}

/// 하루 분량의 플래너 구조 (날짜 + 운동 카드 목록)
@immutable
class PlannerWorkoutDay {
  final DateTime date;
  final List<PlannerExerciseCard> cards;

  const PlannerWorkoutDay({
    required this.date,
    required this.cards,
  });

  PlannerWorkoutDay copyWith({
    DateTime? date,
    List<PlannerExerciseCard>? cards,
  }) {
    return PlannerWorkoutDay(
      date: date ?? this.date,
      cards: cards ?? this.cards,
    );
  }
}
