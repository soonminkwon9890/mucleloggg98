import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/planned_workout_dto.dart';
import '../../data/models/planner_models.dart';

/// 주간 플래너 상태 관리 StateNotifier
///
/// 불변 상태(List<PlannerWorkoutDay>)를 유지하며 드래그/편집/삭제를 처리합니다.
/// 모든 mutating 메서드는 새 리스트를 생성하여 state 에 할당합니다.
class WeeklyPlannerNotifier extends StateNotifier<List<PlannerWorkoutDay>> {
  WeeklyPlannerNotifier() : super(_buildEmptyWeek());

  // ---------------------------------------------------------------------------
  // 초기 상태 생성 헬퍼
  // ---------------------------------------------------------------------------

  /// 다음 주 월~일 7일의 빈 구조를 생성합니다.
  static List<PlannerWorkoutDay> _buildEmptyWeek() {
    final today = _today();
    // weekday: 1=월, 7=일 → 다음 월요일까지 남은 일수
    final daysToNextMonday = 8 - today.weekday; // 1→7, 2→6, ..., 7→1
    final nextMonday = today.add(Duration(days: daysToNextMonday));

    return List.generate(7, (i) {
      final date = nextMonday.add(Duration(days: i));
      return PlannerWorkoutDay(date: date, cards: const []);
    });
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// 상태를 초기 빈 주간 구조로 리셋합니다.
  void reset() => state = _buildEmptyWeek();

  /// AI 생성 [PlannedWorkoutDto] 목록으로 플래너를 채웁니다.
  ///
  /// plan 의 날짜들로부터 해당 주(월~일)를 자동 결정합니다.
  void loadFromPlans(List<PlannedWorkoutDto> plans) {
    if (plans.isEmpty) return;

    // 계획 날짜들을 정규화(시간 제거)
    final normalizedPlanDates = plans
        .map((p) => DateTime(
              p.scheduledDate.year,
              p.scheduledDate.month,
              p.scheduledDate.day,
            ))
        .toList();

    // 가장 이른 날짜가 속한 주의 월요일 계산
    final earliest =
        normalizedPlanDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final monday = earliest.subtract(Duration(days: earliest.weekday - 1));

    // 7일 구조 생성
    final weekDays = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return PlannerWorkoutDay(date: date, cards: const []);
    });

    // 날짜별로 카드 배분
    final populated = weekDays.map((day) {
      final cardsForDay = plans
          .where((plan) {
            final planDate = DateTime(
              plan.scheduledDate.year,
              plan.scheduledDate.month,
              plan.scheduledDate.day,
            );
            return planDate == day.date;
          })
          .map((plan) => PlannerExerciseCard(
                key: UniqueKey(),
                baselineId: plan.baselineId,
                exerciseName: plan.exerciseName,
                targetWeight: plan.targetWeight,
                targetReps: plan.targetReps,
                targetSets: plan.targetSets,
                aiComment: plan.aiComment,
                isAiProposed: true,
              ))
          .toList();
      return day.copyWith(cards: cardsForDay);
    }).toList();

    state = populated;
  }

  /// 같은 날([date]) 안에서 [cardKey] 카드를 [toIndex] 위치로 재정렬합니다.
  void reorderCardWithinDay(Key cardKey, DateTime date, int toIndex) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dayIndex = state.indexWhere((d) => d.date == normalizedDate);
    if (dayIndex == -1) return;

    final day = state[dayIndex];
    final fromIndex = day.cards.indexWhere((c) => c.key == cardKey);
    if (fromIndex == -1) return;

    final cards = List<PlannerExerciseCard>.from(day.cards);
    final card = cards.removeAt(fromIndex);
    final insertAt = toIndex.clamp(0, cards.length);
    cards.insert(insertAt, card);

    final newState = List<PlannerWorkoutDay>.from(state);
    newState[dayIndex] = day.copyWith(cards: cards);
    state = newState;
  }

  /// [cardKey] 에 해당하는 카드를 [toDate] 슬롯으로 이동합니다.
  ///
  /// 출발지와 목적지가 같으면 아무 작업도 하지 않습니다.
  void moveCard(Key cardKey, DateTime toDate) {
    PlannerExerciseCard? cardToMove;
    int fromDayIndex = -1;

    for (int i = 0; i < state.length; i++) {
      final idx = state[i].cards.indexWhere((c) => c.key == cardKey);
      if (idx != -1) {
        cardToMove = state[i].cards[idx];
        fromDayIndex = i;
        break;
      }
    }

    if (cardToMove == null || fromDayIndex == -1) return;

    final normalizedTo =
        DateTime(toDate.year, toDate.month, toDate.day);
    final toDayIndex = state.indexWhere((d) => d.date == normalizedTo);

    if (toDayIndex == -1 || toDayIndex == fromDayIndex) return;

    final newState = state.toList();

    // 출발지에서 제거
    final fromDay = newState[fromDayIndex];
    newState[fromDayIndex] = fromDay.copyWith(
      cards: fromDay.cards.where((c) => c.key != cardKey).toList(),
    );

    // 목적지에 추가 (리스트 끝)
    final toDay = newState[toDayIndex];
    newState[toDayIndex] = toDay.copyWith(
      cards: [...toDay.cards, cardToMove],
    );

    state = newState;
  }

  /// [cardKey] 카드를 [toDate] 날의 [toIndex] 위치에 삽입합니다.
  ///
  /// 인트라-데이(같은 날 재정렬)와 크로스-데이(날짜 간 이동) 모두 처리합니다.
  /// 슬롯 인덱스 기반이므로 호출자는 N+1 슬롯 중 어느 슬롯에 떨어졌는지만 전달하면 됩니다.
  void placeCard(Key cardKey, DateTime toDate, int toIndex) {
    // 1. 출발지 탐색
    PlannerExerciseCard? cardToPlace;
    int fromDayIndex = -1;

    for (int i = 0; i < state.length; i++) {
      final idx = state[i].cards.indexWhere((c) => c.key == cardKey);
      if (idx != -1) {
        cardToPlace = state[i].cards[idx];
        fromDayIndex = i;
        break;
      }
    }
    if (cardToPlace == null || fromDayIndex == -1) return;

    final normalizedTo = DateTime(toDate.year, toDate.month, toDate.day);
    final toDayIndex = state.indexWhere((d) => d.date == normalizedTo);
    if (toDayIndex == -1) return;

    final newState = state.toList();

    // 2. 출발지에서 제거
    final fromDay = newState[fromDayIndex];
    newState[fromDayIndex] = fromDay.copyWith(
      cards: fromDay.cards.where((c) => c.key != cardKey).toList(),
    );

    // 3. 목적지에 특정 인덱스로 삽입
    //    같은 날(fromDayIndex == toDayIndex)이면 이미 카드가 빠진 상태이므로
    //    toIndex 를 clamp 하여 범위 초과를 방지합니다.
    final toCards = List<PlannerExerciseCard>.from(newState[toDayIndex].cards);
    final insertAt = toIndex.clamp(0, toCards.length);
    toCards.insert(insertAt, cardToPlace);
    newState[toDayIndex] = newState[toDayIndex].copyWith(cards: toCards);

    state = newState;
  }

  /// [cardKey] 카드의 내용을 수정합니다.
  void editCard(
    Key cardKey, {
    required String exerciseName,
    required double targetWeight,
    required int targetReps,
    required int targetSets,
  }) {
    state = state.map((day) {
      final updatedCards = day.cards.map((card) {
        if (card.key != cardKey) return card;
        return card.copyWith(
          exerciseName: exerciseName,
          targetWeight: targetWeight,
          targetReps: targetReps,
          targetSets: targetSets,
          // 사용자가 수정하면 AI 제안 태그를 유지 (원본 AI 추천 내용임을 알 수 있도록)
        );
      }).toList();
      return day.copyWith(cards: updatedCards);
    }).toList();
  }

  /// [cardKey] 카드를 삭제합니다.
  void deleteCard(Key cardKey) {
    state = state.map((day) {
      return day.copyWith(
        cards: day.cards.where((c) => c.key != cardKey).toList(),
      );
    }).toList();
  }

  /// 전체 카드 수 (저장 전 검증용)
  int get totalCards =>
      state.fold(0, (sum, day) => sum + day.cards.length);
}

/// 주간 플래너 전역 상태 프로바이더
///
/// autoDispose 사용하지 않음: 사용자가 다른 화면으로 갔다가 돌아왔을 때
/// 편집 내용이 유지됩니다. 새 AI 분석을 원하면 AppBar의 새로고침 버튼을 사용하세요.
final weeklyPlannerProvider =
    StateNotifierProvider<WeeklyPlannerNotifier, List<PlannerWorkoutDay>>(
  (ref) => WeeklyPlannerNotifier(),
);
