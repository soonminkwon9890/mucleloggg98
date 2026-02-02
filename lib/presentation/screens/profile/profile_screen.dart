import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout.dart';
import '../../widgets/profile/exercise_search_sheet.dart';
import '../../widgets/workout/planned_workout_tile.dart';
import '../../widgets/workout/workout_execution_dialog.dart';
import '../../../data/models/workout_completion_input.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ExerciseBaseline>? _selectedDayWorkouts;
  bool _isLoadingWorkouts = false;
  bool _isSearchSheetOpen = false;
  
  // 계획된 운동 상태
  Map<DateTime, PlannedWorkout> _plannedWorkoutsByDate = {};
  List<PlannedWorkout> _selectedDayPlannedWorkouts = [];
  Map<String, String> _exerciseNameMap = {}; // baselineId -> exerciseName 매핑
  bool _isConvertingToLog = false; // 변환 중 로딩 상태
  
  @override
  void initState() {
    super.initState();
    // 초기 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlannedWorkoutsForMonth(_focusedDay);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openExerciseSearchSheet() async {
    if (!mounted) return;
    if (_isSearchSheetOpen) return;

    _isSearchSheetOpen = true;
    // 키보드가 떠있는 상태에서 시트 오픈 시 레이아웃 경합 방지
    FocusScope.of(context).unfocus();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Consumer(
                builder: (context, ref, _) {
                  final asyncItems = ref.watch(exercisesWithHistoryProvider);
                  return asyncItems.when(
                    data: (items) => ExerciseSearchSheet(
                      items: items,
                      scrollController: scrollController,
                      onDateSelected: (date) {
                        if (!mounted) return;
                        setState(() {
                          _selectedDay = date;
                          _focusedDay = date;
                        });
                        _loadWorkoutsForDate(date);
                        _loadPlannedWorkoutsForDate(date);
                      },
                    ),
                    loading: () => Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 44,
                                height: 4,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFBDBDBD),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(999)),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (e, _) => Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            const Center(
                              child: SizedBox(
                                width: 44,
                                height: 4,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFBDBDBD),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(999)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '데이터를 불러오지 못했습니다.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$e',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ref.invalidate(
                                            exercisesWithHistoryProvider);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('다시 시도'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } finally {
      _isSearchSheetOpen = false;
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    }
  }

  /// 특정 월의 계획된 운동 로드
  Future<void> _loadPlannedWorkoutsForMonth(DateTime month) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      
      // 해당 월의 시작일/종료일 계산
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      final plannedWorkouts = await repository.getPlannedWorkoutsByDateRange(
        startDate,
        endDate,
      );
      
      if (mounted) {
        setState(() {
          // 날짜별로 그룹화 (첫 번째 PlannedWorkout만 저장)
          _plannedWorkoutsByDate = {};
          for (final workout in plannedWorkouts) {
            // 변환 완료(로그로 저장된) 계획은 체크박스/플랜 마커에서 제외
            if (workout.isConvertedToLog) continue;
            final dateKey = DateTime(
              workout.scheduledDate.year,
              workout.scheduledDate.month,
              workout.scheduledDate.day,
            );
            // 이미 있으면 유지 (첫 번째 것 우선)
            _plannedWorkoutsByDate.putIfAbsent(dateKey, () => workout);
          }
        });
      }
    } catch (e) {
      // 에러는 조용히 무시 (캘린더는 계속 동작해야 함)
      if (mounted) {
        setState(() {
          _plannedWorkoutsByDate = {};
        });
      }
    }
  }

  /// 특정 날짜의 계획된 운동 로드
  Future<void> _loadPlannedWorkoutsForDate(DateTime date) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      
      // 해당 날짜의 계획된 운동 조회 (운동 이름 포함)
      final (plannedWorkouts, exerciseNameMap) = await repository
          .getPlannedWorkoutsByDateRangeWithNames(date, date);
      
      if (mounted) {
        setState(() {
          // 변환 완료(로그로 저장된) 계획은 체크박스 목록에서 제외
          _selectedDayPlannedWorkouts =
              plannedWorkouts.where((p) => !p.isConvertedToLog).toList();
          _exerciseNameMap = exerciseNameMap;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedDayPlannedWorkouts = [];
          _exerciseNameMap = {};
        });
      }
    }
  }
  
  /// 변환 가능한 계획된 운동이 있는지 확인 (버튼 노출 조건)
  /// is_completed == true && is_converted_to_log == false 인 항목이 하나라도 있으면 true
  bool get _hasConvertiblePlannedWorkouts {
    return _selectedDayPlannedWorkouts.any(
      (plan) => plan.isCompleted && !plan.isConvertedToLog,
    );
  }

  /// 완료된 계획된 운동을 WorkoutSet으로 변환
  Future<void> _completeAndConvertPlannedWorkouts() async {
    if (_selectedDay == null) return;
    
    // 변환 가능한 계획만 필터링
    final convertiblePlans = _selectedDayPlannedWorkouts
        .where((plan) => plan.isCompleted && !plan.isConvertedToLog)
        .toList();
    
    if (convertiblePlans.isEmpty) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);

      // Exercise name map 구성: plan.exerciseName 우선, 없으면 baseline 조회로 보강
      final baselineIds = convertiblePlans.map((p) => p.baselineId).toSet().toList();
      final baselines = await repository.getBaselinesByIds(baselineIds);
      final fetchedNameMap = {for (final b in baselines) b.id: b.exerciseName};

      final exerciseNames = <String, String>{};
      for (final plan in convertiblePlans) {
        exerciseNames[plan.baselineId] =
            plan.exerciseName ?? fetchedNameMap[plan.baselineId] ?? _exerciseNameMap[plan.baselineId] ?? 'Unknown';
      }

      final inputs = await showDialog<List<WorkoutCompletionInput>>(
        context: context,
        builder: (context) => WorkoutExecutionDialog(
          plans: convertiblePlans,
          exerciseNames: exerciseNames,
        ),
      );
      if (inputs == null) return;

      setState(() => _isConvertingToLog = true);
      await repository.completeAndConvertPlannedWorkouts(inputs, convertiblePlans);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동이 보관함에 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 화면 갱신: (1) 계획 목록에서 즉시 제거, (2) 완료된 운동 섹션에 즉시 반영
        await _loadPlannedWorkoutsForDate(_selectedDay!);
        await _loadWorkoutsForDate(_selectedDay!);
        _loadPlannedWorkoutsForMonth(_focusedDay);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConvertingToLog = false);
      }
    }
  }

  Future<void> _loadWorkoutsForDate(DateTime date) async {
    setState(() {
      _isLoadingWorkouts = true;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final workouts = await repository.getWorkoutsByDate(date);
      if (mounted) {
        setState(() {
          _selectedDayWorkouts = workouts;
          _isLoadingWorkouts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedDayWorkouts = [];
          _isLoadingWorkouts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [Wiring] MainScreen(+버튼) -> ProfileScreen(바텀시트) 트리거 연결
    // build에 listen을 두어 Hot Reload/Provider 갱신 후에도 리스너가 끊기지 않게 함.
    ref.listen<int>(profileSearchTriggerProvider, (prev, next) {
      if (prev == next) return;
      _openExerciseSearchSheet(); // 내부에서 _isSearchSheetOpen으로 중복 오픈 방지
    });

    final profileAsync = ref.watch(currentProfileProvider);
    final workoutDatesAsync = ref.watch(workoutDatesProvider);

    return SafeArea(
      child: profileAsync.when(
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 달력 섹션 (운동 기록 날짜 하이라이트)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '운동 기록 달력',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        workoutDatesAsync.when(
                          data: (workoutDates) {
                            return TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  _selectedDay != null &&
                                  isSameDay(_selectedDay!, day),
                              locale: 'ko_KR',
                              calendarFormat: CalendarFormat.month,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              eventLoader: (day) {
                                final now = DateTime.now();
                                final dayDate =
                                    DateTime(day.year, day.month, day.day);
                                final isPast = dayDate.isBefore(
                                  DateTime(now.year, now.month, now.day),
                                );
                                final plannedWorkout =
                                    _plannedWorkoutsByDate[dayDate];

                                final events = <dynamic>[];

                                // 과거 기록 (회색 점)
                                if (isPast &&
                                    workoutDates
                                        .any((date) => isSameDay(date, day))) {
                                  events.add('past_workout');
                                }

                                // 미래 계획 (색상 점)
                                if (!isPast && plannedWorkout != null) {
                                  events.add(plannedWorkout);
                                }

                                return events;
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                                _loadWorkoutsForDate(selectedDay);
                                _loadPlannedWorkoutsForDate(selectedDay);
                              },
                              onPageChanged: (focusedDay) {
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                                _loadPlannedWorkoutsForMonth(focusedDay);
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  if (events.isEmpty) return null;

                                  final hasPastWorkout =
                                      events.contains('past_workout');
                                  final plannedWorkout = events
                                      .whereType<PlannedWorkout>()
                                      .firstOrNull;

                                  // 둘 다 있는 경우: 점 두 개 나란히 표시
                                  if (hasPastWorkout && plannedWorkout != null) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 과거 기록 (회색 작은 점)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(right: 2),
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        // 미래 계획 (색상 점)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                plannedWorkout.colorHex)),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  // 과거 기록만 있는 경우
                                  if (hasPastWorkout) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }

                                  // 미래 계획만 있는 경우
                                  if (plannedWorkout != null) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                            plannedWorkout.colorHex)),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }

                                  return null;
                                },
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => SizedBox(
                            height: 300,
                            child: Center(
                              child: Text('오류: $error'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 선택된 날짜의 운동 리스트
                if (_selectedDay == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '날짜를 선택하세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_isLoadingWorkouts)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_selectedDayWorkouts == null)
                  const SizedBox.shrink()
                else if (_selectedDayWorkouts!.isEmpty &&
                    _selectedDayPlannedWorkouts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '선택한 날짜에 운동 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // 완료된 운동 섹션
                      if (_selectedDayWorkouts != null &&
                          _selectedDayWorkouts!.isNotEmpty)
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일 완료된 운동',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ..._selectedDayWorkouts!.map((baseline) {
                                return ListTile(
                                  leading: baseline.thumbnailUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            baseline.thumbnailUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.fitness_center,
                                                size: 40,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.fitness_center,
                                          size: 40,
                                        ),
                                  title: Text(baseline.exerciseName),
                                  subtitle: baseline.workoutSets != null &&
                                          baseline.workoutSets!.isNotEmpty
                                      ? Text(
                                          '${baseline.workoutSets!.length}세트',
                                        )
                                      : null,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // TODO: 운동 분석 화면으로 이동 (필요 시 구현)
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      // 계획된 운동 섹션
                      if (_selectedDayPlannedWorkouts.isNotEmpty) ...[
                        if (_selectedDayWorkouts != null &&
                            _selectedDayWorkouts!.isNotEmpty)
                          const SizedBox(height: 16),
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일 계획된 운동',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ..._selectedDayPlannedWorkouts
                                  .map((plannedWorkout) {
                                final exerciseName =
                                    plannedWorkout.exerciseName ??
                                        _exerciseNameMap[
                                            plannedWorkout.baselineId] ??
                                        '알 수 없음';
                                return PlannedWorkoutTile(
                                  plannedWorkout: plannedWorkout,
                                  exerciseName: exerciseName,
                                  onUpdated: () {
                                    _loadPlannedWorkoutsForDate(_selectedDay!);
                                    _loadPlannedWorkoutsForMonth(
                                        _focusedDay); // 캘린더 마커 갱신
                                  },
                                );
                              }),
                              // "운동 완료 및 저장" 버튼 (조건부 표시)
                              if (_hasConvertiblePlannedWorkouts) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isConvertingToLog
                                          ? null
                                          : _completeAndConvertPlannedWorkouts,
                                      icon: _isConvertingToLog
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.check_circle),
                                      label: const Text('운동 완료 및 저장'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류: $error'),
        ),
      ),
    );
  }
}

