import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/ai_consent_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../widgets/profile/exercise_search_sheet.dart';
import '../../widgets/workout/planned_workout_tile.dart';
import '../../widgets/workout/routine_generation_dialog.dart';
import '../workout/workout_analysis_screen.dart';

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
  bool _isGeneratingRoutine = false; // AI 루틴 생성 중 로딩 상태

  // [Issue #4 Fix] Race condition 방지를 위한 요청 추적
  int _dateRequestId = 0;

  @override
  void initState() {
    super.initState();

    // 초기 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlannedWorkoutsForMonth(_focusedDay);
    });
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
          // [Phase 1] 고정 높이 85%로 설정 (DraggableScrollableSheet 제거)
          final sheetHeight = MediaQuery.of(context).size.height * 0.85;
          return Consumer(
            builder: (context, ref, _) {
              final asyncItems = ref.watch(exercisesWithHistoryProvider);
              return asyncItems.when(
                data: (items) => SizedBox(
                  height: sheetHeight,
                  child: ExerciseSearchSheet(
                    items: items,
                    onDateSelected: (date) {
                      if (!mounted) return;
                      // [Issue #4 Fix] 새 요청 ID 생성하여 이전 요청 무효화
                      _dateRequestId++;
                      final currentRequestId = _dateRequestId;

                      setState(() {
                        _selectedDay = date;
                        _focusedDay = date;
                      });
                      _loadWorkoutsForDate(date, requestId: currentRequestId);
                      _loadPlannedWorkoutsForDate(date, requestId: currentRequestId);
                    },
                  ),
                ),
                loading: () => SizedBox(
                  height: sheetHeight,
                  child: Material(
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
                ),
                error: (e, _) => SizedBox(
                      height: sheetHeight,
                      child: Material(
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
                    ),
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
  /// [Issue #4 Fix] requestId를 사용하여 stale 응답 무시
  /// [D.4] activeOnly 파라미터로 DB 레벨 필터링 (UI 필터링 제거)
  Future<void> _loadPlannedWorkoutsForDate(DateTime date, {required int requestId}) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);

      // D.4: 변환되지 않은 운동만 DB에서 직접 조회 (네트워크 최적화)
      final (plannedWorkouts, exerciseNameMap) = await repository
          .getPlannedWorkoutsByDateRangeWithNames(date, date, activeOnly: true);

      // [Issue #4 Fix] 요청 ID가 현재와 다르면 stale 응답이므로 무시
      if (!mounted || requestId != _dateRequestId) return;

      setState(() {
        // D.4: UI 레벨 필터링 제거됨 - DB에서 이미 필터링 완료
        _selectedDayPlannedWorkouts = plannedWorkouts;
        _exerciseNameMap = exerciseNameMap;
      });
    } catch (e) {
      // [Issue #4 Fix] 에러 처리 시에도 요청 ID 확인
      if (!mounted || requestId != _dateRequestId) return;

      setState(() {
        _selectedDayPlannedWorkouts = [];
        _exerciseNameMap = {};
      });
    }
  }
  
  // [REMOVED - Requirement 3] _hasConvertiblePlannedWorkouts getter 제거
  // [REMOVED - Requirement 3] _completeAndConvertPlannedWorkouts method 제거
  // 계획된 운동은 이제 해당 날짜에 홈 화면에서 실행됩니다.

  /// [Issue #4 Fix] requestId를 사용하여 stale 응답 무시
  Future<void> _loadWorkoutsForDate(DateTime date, {required int requestId}) async {
    setState(() {
      _isLoadingWorkouts = true;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      // [Fix] 캘린더는 완료된 운동만 표시 (홈 화면과 구분)
      final workouts = await repository.getWorkoutsByDate(date, completedOnly: true);

      // [Issue #4 Fix] 요청 ID가 현재와 다르면 stale 응답이므로 무시
      if (!mounted || requestId != _dateRequestId) return;

      setState(() {
        _selectedDayWorkouts = workouts;
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      // [Issue #4 Fix] 에러 처리 시에도 요청 ID 확인
      if (!mounted || requestId != _dateRequestId) return;

      setState(() {
        _selectedDayWorkouts = [];
        _isLoadingWorkouts = false;
      });
    }
  }

  /// 완료된 운동 옵션 BottomSheet 표시 (3-dots 메뉴)
  void _showCompletedWorkoutOptionsSheet(ExerciseBaseline baseline) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 운동 이름 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  baseline.exerciseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // 기록 보기
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('기록 보기'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final dateKey = DateFormatter.getDateGroupKey(_selectedDay!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutAnalysisScreen(
                        exerciseName: baseline.exerciseName,
                        initialDateKey: dateKey,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// AI 코칭 요청 진입점 — PIPA 동의 확인 후 실제 생성 메서드를 호출합니다.
  Future<void> _handleAiCoachingRequest() async {
    if (_isGeneratingRoutine) return;
    final consented = await AiConsentHelper.ensureConsent(context);
    if (!consented || !mounted) return;
    await _generateWeeklyRoutine();
  }

  /// AI 루틴 생성 메서드
  Future<void> _generateWeeklyRoutine() async {
    if (_isGeneratingRoutine) return;
    setState(() => _isGeneratingRoutine = true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'AI가 루틴을 분석 중입니다...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '이번 주 운동 기록을 기반으로\n최적의 다음 주 계획을 만들고 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final sessions = await repo.getLastWeekSessions();
      if (sessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          // [Phase 3] 개선된 빈 상태 다이얼로그
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
              title: const Text('데이터 부족'),
              content: const Text(
                '이번 주(월~일)에 완료된 운동 기록이 있어야\nAI가 다음 주 계획을 만들어 드릴 수 있어요!\n\n운동을 완료하고 다시 시도해주세요.',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final userGoal = await repo.getUserGoal();
      
      // [Step 1] 모든 세션의 bestSet 조회
      final bestSetsFutures = sessions.map((s) async {
        final bestSet = await repo.getLastWeekBestSet(s.baselineId, s.workoutDate);
        return MapEntry(s.baselineId, bestSet);
      }).toList();
      final allBestSetsMap = Map.fromEntries(await Future.wait(bestSetsFutures));

      // [Step 2] 0kg/0회 운동 제외: 실제 기록이 있는 baseline만 유지
      final validBestSetsMap = Map<String, (double, int)>.fromEntries(
        allBestSetsMap.entries.where((entry) {
          final (weight, reps) = entry.value;
          return weight > 0 || reps > 0; // 무게 또는 횟수 중 하나라도 있으면 유지
        }),
      );

      // [Step 3] 유효한 baseline만 포함된 세션으로 필터링
      final filteredSessions = sessions
          .where((s) => validBestSetsMap.containsKey(s.baselineId))
          .toList();

      // 필터링 후 세션이 없으면 조기 종료
      if (filteredSessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          // [Phase 3] 개선된 빈 상태 다이얼로그
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.fitness_center, size: 48, color: Colors.orange),
              title: const Text('완료된 기록 없음'),
              content: const Text(
                '이번 주에 무게/횟수가 기록된 운동이 없어요.\n\n운동을 완료하고 세트 정보를 저장한 뒤\n다시 시도해주세요!',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // [Step 4] 유효한 baseline만 조회
      final validBaselineIds = filteredSessions.map((s) => s.baselineId).toSet().toList();
      final baselines = await repo.getBaselinesByIds(validBaselineIds);
      final baselineMap = {for (var b in baselines) b.id: b};

      // [Step 5] AI 호출 (0kg/0회 제외된 데이터만 전달)
      final plans = await WorkoutRecommendationService.generateWeeklyPlan(
        lastWeekSessions: filteredSessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: validBestSetsMap,
      );

      if (mounted) {
        Navigator.pop(context);
        if (plans.isNotEmpty) {
          await _showRoutineGenerationDialog(plans);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('생성된 루틴이 없습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingRoutine = false);
    }
  }

  /// 루틴 생성 다이얼로그 표시 (결과: 날짜가 주입된 루틴 + 색상)
  Future<void> _showRoutineGenerationDialog(List<PlannedWorkoutDto> plans) async {
    final result = await showDialog<RoutineApplyResult>(
      context: context,
      builder: (context) => RoutineGenerationDialog(routines: plans),
    );
    if (result == null || !mounted) return;
    await _savePlannedWorkouts(result.routines, result.colorHex);
  }

  Future<void> _savePlannedWorkouts(
    List<PlannedWorkoutDto> routines,
    String colorHex,
  ) async {
    if (routines.isEmpty) return;
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final plans = routines
          .map(
            (dto) => dto.toPlannedWorkout(
              colorHex: colorHex,
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      await repository.savePlannedWorkouts(plans);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // ProfileScreen 캘린더 즉시 갱신 (저장 성공 시)
      ref.read(plannedWorkoutsRefreshProvider.notifier).state++;

      final dateLabel = DateFormatter.formatMonthDay(routines.first.scheduledDate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dateLabel에 운동이 추가되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

    // Provider 감지하여 캘린더 갱신 (AI 계획 수립 후 즉시 동기화)
    ref.listen(plannedWorkoutsRefreshProvider, (previous, next) {
      if (previous != next && mounted) {
        _loadPlannedWorkoutsForMonth(_focusedDay);
      }
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '운동 기록 달력',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openExerciseSearchSheet(),
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('운동 검색'),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // [AI 루틴 생성 버튼]
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingRoutine
                                ? null
                                : _handleAiCoachingRequest,
                            icon: _isGeneratingRoutine
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('AI 강도 측정을 통해 다음주 계획을 만들어 보세요!'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
                                // [Issue #4 Fix] 새 요청 ID 생성하여 이전 요청 무효화
                                _dateRequestId++;
                                final currentRequestId = _dateRequestId;

                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                                _loadWorkoutsForDate(selectedDay, requestId: currentRequestId);
                                _loadPlannedWorkoutsForDate(selectedDay, requestId: currentRequestId);
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
                  const EmptyStateCard(
                    icon: Icons.event_busy,
                    title: '선택한 날짜에 운동 기록이 없습니다',
                  )
                else
                  Column(
                    children: [
                      // 완료된 운동 섹션
                      if (_selectedDayWorkouts != null &&
                          _selectedDayWorkouts!.isNotEmpty)
                        Card(
                          clipBehavior: Clip.antiAlias,
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
                              Column(
                                children: _selectedDayWorkouts!.map((baseline) {
                                  return ListTile(
                                    key: ValueKey('completed_${baseline.id}'),
                                    leading: baseline.thumbnailUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              baseline.thumbnailUrl!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
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
                                    // 3-dots 메뉴 버튼
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showCompletedWorkoutOptionsSheet(baseline),
                                    ),
                                    onTap: () {
                                      final dateKey = DateFormatter.getDateGroupKey(_selectedDay!);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkoutAnalysisScreen(
                                            exerciseName: baseline.exerciseName,
                                            initialDateKey: dateKey,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      // 계획된 운동 섹션
                      if (_selectedDayPlannedWorkouts.isNotEmpty) ...[
                        if (_selectedDayWorkouts != null &&
                            _selectedDayWorkouts!.isNotEmpty)
                          const SizedBox(height: 16),
                        Card(
                          clipBehavior: Clip.antiAlias,
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
                              Column(
                                children: _selectedDayPlannedWorkouts
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
                                      // [Issue #4 Fix] 새 요청 ID 생성
                                      _dateRequestId++;
                                      final currentRequestId = _dateRequestId;

                                      _loadPlannedWorkoutsForDate(_selectedDay!, requestId: currentRequestId);
                                      _loadPlannedWorkoutsForMonth(
                                          _focusedDay); // 캘린더 마커 갱신
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
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

extension on PlannedWorkoutDto {
  PlannedWorkout toPlannedWorkout({
    required String colorHex,
    required DateTime createdAt,
  }) {
    return PlannedWorkout(
      id: const Uuid().v4(),
      userId: '',
      baselineId: baselineId,
      scheduledDate: scheduledDate,
      targetWeight: targetWeight,
      targetReps: targetReps,
      targetSets: targetSets,
      aiComment: aiComment,
      isCompleted: false,
      exerciseName: exerciseName,
      isConvertedToLog: false,
      createdAt: createdAt,
      colorHex: colorHex,
    );
  }
}
