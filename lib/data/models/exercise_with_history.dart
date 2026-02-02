/// 운동 수행 기록(히스토리) 기반 검색용 DTO
///
/// - JSON 직렬화 불필요 (Plain Dart Class)
/// - [performedDates]는 날짜만(연/월/일) 들어오며, 생성자에서 최신순(내림차순) 정렬됨
class ExerciseWithHistory {
  final String baselineId;
  final String exerciseName;
  final List<DateTime> performedDates;

  ExerciseWithHistory({
    required this.baselineId,
    required this.exerciseName,
    required List<DateTime> performedDates,
  }) : performedDates = (List<DateTime>.from(performedDates)
          ..sort((a, b) => b.compareTo(a)));
}

