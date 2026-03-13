import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workout_provider.dart';
import '../workout/workout_analysis_screen.dart';
import 'routine_detail_screen.dart'; // [Phase 3]
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout.dart';
import '../../../utils/premium_guidance_dialog.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/routine_item.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/enums/exercise_enums.dart';

/// 관리 페이지 (운동 보관함 및 루틴 관리)
class ManagementScreen extends ConsumerStatefulWidget {
  /// [Phase 1] 진입 경로에 따른 모드 설정
  /// - true: Selection Mode (Path A: "+ 운동 추가하기" → "내 보관함에서 불러오기")
  /// - false: Management Mode (Path B: "보관함" 버튼)
  final bool isSelectionMode;

  const ManagementScreen({
    super.key,
    required this.isSelectionMode,
  });

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // [Phase 1] 운동 보관함 선택 상태 (탭 전환 시 유지)
  // 초기값은 widget.isSelectionMode에서 설정됨 (initState에서)
  late bool _isSelectionMode;
  final Set<String> _selectedBaselineIds = {};

  // [Phase 1] 루틴 탭 선택 상태
  final Set<String> _selectedRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // [Phase 1] 진입 경로에 따른 초기 모드 설정
    _isSelectionMode = widget.isSelectionMode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 운동 선택 토글
  void _toggleSelection(String baselineId) {
    setState(() {
      if (_selectedBaselineIds.contains(baselineId)) {
        _selectedBaselineIds.remove(baselineId);
      } else {
        _selectedBaselineIds.add(baselineId);
      }
    });
  }

  /// 선택 초기화 (스케줄링 완료 또는 선택 해제 시 호출)
  void _clearSelection() {
    setState(() {
      _selectedBaselineIds.clear();
    });
  }

  /// 루틴 선택 토글
  void _toggleRoutineSelection(String routineId) {
    setState(() {
      if (_selectedRoutineIds.contains(routineId)) {
        _selectedRoutineIds.remove(routineId);
      } else {
        _selectedRoutineIds.add(routineId);
      }
    });
  }

  /// 루틴 선택 초기화
  void _clearRoutineSelection() {
    setState(() {
      _selectedRoutineIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '운동 보관함'),
            Tab(text: '나만의 루틴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ExerciseLibraryTab(
            isSelectionMode: _isSelectionMode,
            selectedBaselineIds: _selectedBaselineIds,
            onToggleSelection: _toggleSelection,
            onClearSelection: _clearSelection,
          ),
          _RoutinesTab(
            isSelectionMode: _isSelectionMode,
            selectedRoutineIds: _selectedRoutineIds,
            onToggleSelection: _toggleRoutineSelection,
            onClearSelection: _clearRoutineSelection,
          ),
        ],
      ),
    );
  }
}

/// 탭 1: 운동 보관함
class _ExerciseLibraryTab extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final Set<String> selectedBaselineIds;
  final void Function(String) onToggleSelection;
  final VoidCallback onClearSelection;

  const _ExerciseLibraryTab({
    required this.isSelectionMode,
    required this.selectedBaselineIds,
    required this.onToggleSelection,
    required this.onClearSelection,
  });

  @override
  ConsumerState<_ExerciseLibraryTab> createState() =>
      _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends ConsumerState<_ExerciseLibraryTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  BodyPart _selectedBodyPart = BodyPart.upper;
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true; // 탭 전환 시 상태 유지

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          final tabs = [BodyPart.upper, BodyPart.lower, BodyPart.full];
          _selectedBodyPart = tabs[_tabController.index];
          // 선택 상태는 유지 (부위 탭 전환 시에도 초기화하지 않음)
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ExerciseBaseline> _filterBaselines(List<ExerciseBaseline> baselines) {
    return baselines.where((baseline) {
      return baseline.bodyPart == _selectedBodyPart;
    }).toList();
  }

  /// 운동 옵션 메뉴 표시 (운동 기록 보기, 삭제)
  void _showExerciseOptions(ExerciseBaseline baseline) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('운동 기록 보기'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutAnalysisScreen(
                        exerciseName: baseline.exerciseName,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAndDeleteBaseline(baseline);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // [REMOVED - Task 1] _addToToday() 제거
  // 로직이 _planWorkoutForDate()로 통합됨

  Future<void> _confirmAndDeleteBaseline(ExerciseBaseline baseline) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(workoutRepositoryProvider);

    // 루틴 포함 여부 검사
    final routinesContainingExercise =
        await repository.getRoutinesByExerciseName(baseline.exerciseName);

    if (!mounted) return;

    bool confirmDelete = false;
    if (routinesContainingExercise.isNotEmpty) {
      // 루틴에 포함되어 있으면 경고 다이얼로그
      final routineNames =
          routinesContainingExercise.map((r) => r.name).join(', ');
      confirmDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('운동 삭제 경고'),
              content:
                  Text('이 운동은 다음 루틴에 포함되어 있습니다: $routineNames\n\n모두 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      // 루틴에 포함되어 있지 않으면 일반 확인 다이얼로그
      confirmDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('운동 삭제 확인'),
              content: Text(
                  '${baseline.exerciseName}을(를) 정말 삭제하시겠습니까?\n\n모든 기록이 삭제됩니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmDelete || !mounted) return;

    // RPC 함수 호출
    try {
      await repository.deleteBaseline(baseline.id, baseline.exerciseName);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // Provider 갱신 (화면 즉시 업데이트)
      ref.invalidate(baselinesProvider);
      ref.invalidate(archivedBaselinesProvider); // 보관함 화면 갱신 (중요!)
      ref.invalidate(workoutDatesProvider);
      ref.invalidate(routinesProvider); // 루틴 아이템도 삭제될 수 있으므로 갱신

      messenger.showSnackBar(
        SnackBar(content: Text('${baseline.exerciseName}이(가) 삭제되었습니다.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('삭제 오류: $e')),
      );
    }
  }

  /// [NEW - Task 1] 운동 계획 시트 표시
  /// 2/3 높이의 BottomSheet에 캘린더를 표시하고, 날짜 선택 시 "운동 계획하기" 버튼 활성화
  Future<void> _showWorkoutPlanSheet() async {
    if (widget.selectedBaselineIds.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final baselines = ref.read(archivedBaselinesProvider).value ?? [];
    final selectedBaselines =
        baselines.where((b) => widget.selectedBaselineIds.contains(b.id)).toList();

    if (selectedBaselines.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('선택된 운동을 찾을 수 없습니다.')),
      );
      return;
    }

    // 캘린더 상태 관리
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay;
    Map<DateTime, PlannedWorkout> plannedWorkoutsByDate = {};

    // Planned workouts 로드 함수
    Future<void> loadPlannedWorkouts(DateTime month) async {
      try {
        final repository = ref.read(workoutRepositoryProvider);
        final startDate = DateTime(month.year, month.month, 1);
        final endDate = DateTime(month.year, month.month + 1, 0);

        final plannedWorkouts = await repository.getPlannedWorkoutsByDateRange(
          startDate,
          endDate,
        );

        plannedWorkoutsByDate = {};
        for (final workout in plannedWorkouts) {
          if (workout.isConvertedToLog) continue;
          final dateKey = DateTime(
            workout.scheduledDate.year,
            workout.scheduledDate.month,
            workout.scheduledDate.day,
          );
          plannedWorkoutsByDate.putIfAbsent(dateKey, () => workout);
        }
      } catch (e) {
        plannedWorkoutsByDate = {};
      }
    }

    // 초기 로드
    await loadPlannedWorkouts(focusedDay);

    if (!mounted) return;

    // BottomSheet 표시
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final screenHeight = MediaQuery.of(context).size.height;
            final sheetHeight = screenHeight * 2 / 3; // 2/3 높이

            return Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
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
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedBaselines.length}개 운동 선택됨',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '운동할 날짜를 선택하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 캘린더
                  Expanded(
                    child: SingleChildScrollView(
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) =>
                            selectedDay != null && isSameDay(selectedDay!, day),
                        locale: 'ko_KR',
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        eventLoader: (day) {
                          final dayDate = DateTime(day.year, day.month, day.day);
                          final plannedWorkout = plannedWorkoutsByDate[dayDate];
                          return plannedWorkout != null ? [plannedWorkout] : [];
                        },
                        onDaySelected: (selected, focused) {
                          setSheetState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) async {
                          setSheetState(() {
                            focusedDay = focused;
                          });
                          await loadPlannedWorkouts(focused);
                          setSheetState(() {});
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
                            final plannedWorkout =
                                events.whereType<PlannedWorkout>().firstOrNull;
                            if (plannedWorkout != null) {
                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(plannedWorkout.colorHex)),
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
                      ),
                    ),
                  ),
                  // 하단 버튼 (날짜 선택 시에만 표시)
                  if (selectedDay != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // [CRITICAL] 날짜 비교 및 저장 로직
                              await _planWorkoutForDate(
                                selectedBaselines,
                                selectedDay!,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _formatDateLabel(selectedDay!),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 날짜 라벨 포맷 (오늘/내일/특정 날짜)
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return '오늘 운동하기';
    } else if (selectedDate == today.add(const Duration(days: 1))) {
      return '내일 (${date.month}/${date.day}) 운동 계획하기';
    } else {
      return '${date.month}/${date.day} 운동 계획하기';
    }
  }

  /// [CRITICAL] 운동 계획 저장 로직
  /// - 오늘: 홈 화면에 메모리 Draft로 추가 (기존 _addToToday 로직)
  /// - 미래: planned_workouts 테이블에 저장 (addNewExercise 로직 복제)
  Future<void> _planWorkoutForDate(
    List<ExerciseBaseline> selectedBaselines,
    DateTime selectedDate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final normalizedSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isFutureDate = normalizedSelected.isAfter(normalizedToday);

    try {
      if (!isFutureDate) {
        // [Case A: 오늘] - 기존 _addToToday 로직 사용 (DB 즉시 저장)
        await ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
          selectedBaselines,
          routineId: null,
        );

        // 선택 초기화 (부모 상태)
        widget.onClearSelection();

        messenger.showSnackBar(
          SnackBar(
            content: Text('${selectedBaselines.length}개 운동을 오늘 목록에 추가했습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // [Case B: 미래 날짜] - planned_workouts 테이블에 저장
        final repository = ref.read(workoutRepositoryProvider);
        final userId = SupabaseService.currentUser?.id;
        if (userId == null) {
          throw Exception('로그인이 필요합니다.');
        }

        // 각 선택된 운동에 대해 planned_workout 생성
        final plannedWorkouts = <PlannedWorkout>[];
        for (final baseline in selectedBaselines) {
          // 1. exercise_baseline을 DB에 확보 (ensureExerciseVisible)
          final persistedBaseline = await repository.ensureExerciseVisible(
            baseline.exerciseName,
            baseline.bodyPart?.code ?? 'full',
            baseline.targetMuscles ?? [],
          );

          // 2. planned_workout 생성 (Manual Addition: 0kg, 0회, 1세트)
          final plannedWorkout = PlannedWorkout(
            id: const Uuid().v4(),
            userId: userId,
            baselineId: persistedBaseline.id,
            scheduledDate: normalizedSelected,
            targetWeight: 0.0, // Manual: 빈 값
            targetReps: 0,     // Manual: 빈 값
            targetSets: 1,     // Manual: 기본 1세트
            exerciseName: baseline.exerciseName,
            isCompleted: false,
            isConvertedToLog: false,
            colorHex: '0xFF4CAF50', // 녹색 (수동 추가 구분)
            createdAt: DateTime.now(),
          );

          plannedWorkouts.add(plannedWorkout);
        }

        // 3. planned_workouts 테이블에 일괄 저장
        await repository.savePlannedWorkouts(plannedWorkouts);

        // 4. 캘린더 화면 갱신 트리거
        ref.read(plannedWorkoutsRefreshProvider.notifier).state++;

        // 선택 초기화 (부모 상태)
        widget.onClearSelection();

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${selectedBaselines.length}개 운동이 ${selectedDate.month}월 ${selectedDate.day}일에 계획되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('운동 계획 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    final baselinesAsync = ref.watch(archivedBaselinesProvider);
    final isSelectionMode = widget.isSelectionMode;
    final selectedIds = widget.selectedBaselineIds;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: BodyPart.values.map((bodyPart) => Tab(text: bodyPart.label)).toList(),
        ),
        // [Phase 2] 헤더 영역: Selection Mode에서만 안내 텍스트 표시
        if (isSelectionMode)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              '운동을 선택하고 날짜를 지정하세요.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: baselinesAsync.when(
            data: (baselines) {
              final filtered = _filterBaselines(baselines);

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('해당 부위의 운동이 없습니다'),
                );
              }

              return Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      // 하단 버튼이 있을 때 여백 확보
                      bottom: (isSelectionMode && selectedIds.isNotEmpty) ? 130 : 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final baseline = filtered[index];
                      final isSelected = selectedIds.contains(baseline.id);
                      final targetMusclesText =
                          (baseline.targetMuscles != null && baseline.targetMuscles!.isNotEmpty)
                              ? baseline.targetMuscles!.join(', ')
                              : '부위 미설정';
                      final bodyPartLabel = baseline.bodyPart?.label;
                      final subtitleText = (bodyPartLabel == null || bodyPartLabel.trim().isEmpty)
                          ? targetMusclesText
                          : '$bodyPartLabel · $targetMusclesText';

                      // [Phase 3] 선택 모드에 따라 카드 UI 변경
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: (isSelectionMode && isSelected)
                            ? Colors.blue.withValues(alpha: 0.15)
                            : null,
                        child: InkWell(
                          onTap: isSelectionMode
                              ? () => widget.onToggleSelection(baseline.id)
                              : () => _showExerciseOptions(baseline), // [Phase 3] Management Mode: 탭 시 옵션 시트 표시
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              // [Phase 3] 선택 모드에서만 체크박스 표시
                              leading: isSelectionMode
                                  ? Icon(
                                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                      size: 28,
                                    )
                                  : Icon(
                                      Icons.fitness_center,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                              title: Text(
                                baseline.exerciseName,
                                style: TextStyle(
                                  fontWeight: (isSelectionMode && isSelected)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: (isSelectionMode && isSelected)
                                      ? Colors.blue[700]
                                      : Colors.grey[600],
                                ),
                              ),
                              // [Phase 3] 3-dots 메뉴 제거 - 카드 탭으로 대체
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // [Phase 4] 하단 액션 바 (선택 모드 + 선택된 운동이 있을 때)
                  if (isSelectionMode && selectedIds.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 메인 액션 버튼
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showWorkoutPlanSheet,
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    '${selectedIds.length}개 운동 다시하기',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 취소 버튼 - 선택 해제 후 화면 유지
                              TextButton(
                                onPressed: widget.onClearSelection,
                                child: Text(
                                  '선택 해제',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('오류: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

/// 탭 2: 나만의 루틴
class _RoutinesTab extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final Set<String> selectedRoutineIds;
  final void Function(String) onToggleSelection;
  final VoidCallback onClearSelection;

  const _RoutinesTab({
    required this.isSelectionMode,
    required this.selectedRoutineIds,
    required this.onToggleSelection,
    required this.onClearSelection,
  });

  @override
  ConsumerState<_RoutinesTab> createState() => _RoutinesTabState();
}

class _RoutinesTabState extends ConsumerState<_RoutinesTab> {
  /// 루틴 생성 모달 표시
  Future<void> _showCreateRoutineModal(BuildContext context) async {
    final selectedBaselineIds = <String>{};
    String selectedBodyPart = '상체';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // 헤더
                AppBar(
                  title: const Text('운동 선택'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                // 필터 칩
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: ['상체', '하체', '전신'].map((part) {
                      return FilterChip(
                        label: Text(part),
                        selected: selectedBodyPart == part,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedBodyPart = part;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                // 운동 목록
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final baselinesAsync = ref.watch(archivedBaselinesProvider);
                      return baselinesAsync.when(
                        data: (baselines) {
                          final selectedBodyPartEnum = BodyPartParsing.fromKorean(selectedBodyPart);
                          final filtered = baselines.where((baseline) {
                            return baseline.bodyPart == selectedBodyPartEnum;
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text('해당 부위의 운동이 없습니다'),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final baseline = filtered[index];
                              final isSelected =
                                  selectedBaselineIds.contains(baseline.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedBaselineIds.add(baseline.id);
                                    } else {
                                      selectedBaselineIds.remove(baseline.id);
                                    }
                                  });
                                },
                                title: Text(baseline.exerciseName),
                                subtitle: Text(
                                  ((baseline.targetMuscles != null &&
                                              baseline.targetMuscles!
                                                  .isNotEmpty)
                                          ? baseline.targetMuscles!.join(', ')
                                          : '부위 미설정')
                                      .toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                secondary: baseline.thumbnailUrl != null &&
                                        baseline.thumbnailUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          baseline.thumbnailUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.fitness_center,
                                                size: 50);
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.fitness_center,
                                        size: 50),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('오류: $error')),
                      );
                    },
                  ),
                ),
                // 하단 버튼
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        '${selectedBaselineIds.length}개 선택됨',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton(
                        onPressed: selectedBaselineIds.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(context); // 모달 닫기
                                await _showRoutineNameDialog(
                                  context,
                                  selectedBaselineIds,
                                );
                              },
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 루틴 이름 입력 다이얼로그 표시 및 저장
  Future<void> _showRoutineNameDialog(
    BuildContext context,
    Set<String> selectedBaselineIds,
  ) async {
    // [안전 장치] 비동기 작업 전에 Messenger 객체를 미리 확보
    final messenger = ScaffoldMessenger.of(context);

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 이름 입력'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '예: 상체 루틴',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final baselines = await repository.getArchivedBaselines();
      final selectedBaselines =
          baselines.where((b) => selectedBaselineIds.contains(b.id)).toList();

      if (selectedBaselines.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('선택된 운동이 없습니다.')),
        );
        return;
      }

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final routine = Routine(
        id: const Uuid().v4(),
        userId: userId,
        name: result,
        createdAt: DateTime.now(),
      );

      final items = selectedBaselines.asMap().entries.map((entry) {
        final index = entry.key;
        final baseline = entry.value;
        return RoutineItem(
          id: const Uuid().v4(),
          routineId: routine.id,
          exerciseName: baseline.exerciseName,
          bodyPart: baseline.bodyPart,
          sortOrder: index,
          createdAt: DateTime.now(),
        );
      }).toList();

      await repository.saveRoutine(routine, items);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // Provider 갱신
      ref.invalidate(routinesProvider);

      messenger.showSnackBar(
        const SnackBar(content: Text('루틴이 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  /// [Phase 2] 선택된 루틴들의 운동 계획 시트 표시
  Future<void> _showSelectedRoutinesPlanSheet(List<Routine> allRoutines) async {
    final selectedIds = widget.selectedRoutineIds;
    if (selectedIds.isEmpty) return;

    // 선택된 루틴들 필터링
    final selectedRoutines = allRoutines
        .where((r) => selectedIds.contains(r.id))
        .toList();

    if (selectedRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택된 루틴을 찾을 수 없습니다.')),
      );
      return;
    }

    // 선택된 루틴들의 모든 운동 수집
    final allExerciseNames = <String>[];
    for (final routine in selectedRoutines) {
      if (routine.routineItems != null) {
        for (final item in routine.routineItems!) {
          allExerciseNames.add(item.exerciseName);
        }
      }
    }

    if (allExerciseNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택된 루틴에 운동이 없습니다.')),
      );
      return;
    }

    // 캘린더 상태 관리
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay;
    Map<DateTime, PlannedWorkout> plannedWorkoutsByDate = {};

    // Planned workouts 로드 함수
    Future<void> loadPlannedWorkouts(DateTime month) async {
      try {
        final repository = ref.read(workoutRepositoryProvider);
        final startDate = DateTime(month.year, month.month, 1);
        final endDate = DateTime(month.year, month.month + 1, 0);

        final plannedWorkouts = await repository.getPlannedWorkoutsByDateRange(
          startDate,
          endDate,
        );

        plannedWorkoutsByDate = {};
        for (final workout in plannedWorkouts) {
          if (workout.isConvertedToLog) continue;
          final dateKey = DateTime(
            workout.scheduledDate.year,
            workout.scheduledDate.month,
            workout.scheduledDate.day,
          );
          plannedWorkoutsByDate.putIfAbsent(dateKey, () => workout);
        }
      } catch (e) {
        plannedWorkoutsByDate = {};
      }
    }

    // 초기 로드
    await loadPlannedWorkouts(focusedDay);

    if (!mounted) return;

    // BottomSheet 표시
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final screenHeight = MediaQuery.of(context).size.height;
            final sheetHeight = screenHeight * 2 / 3;

            return Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
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
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedRoutines.length}개 루틴 선택됨',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '총 ${allExerciseNames.length}개 운동 · 운동할 날짜를 선택하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 캘린더
                  Expanded(
                    child: SingleChildScrollView(
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) =>
                            selectedDay != null && isSameDay(selectedDay!, day),
                        locale: 'ko_KR',
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        eventLoader: (day) {
                          final dayDate = DateTime(day.year, day.month, day.day);
                          final plannedWorkout = plannedWorkoutsByDate[dayDate];
                          return plannedWorkout != null ? [plannedWorkout] : [];
                        },
                        onDaySelected: (selected, focused) {
                          setSheetState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) async {
                          setSheetState(() {
                            focusedDay = focused;
                          });
                          await loadPlannedWorkouts(focused);
                          setSheetState(() {});
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
                            final plannedWorkout =
                                events.whereType<PlannedWorkout>().firstOrNull;
                            if (plannedWorkout != null) {
                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(plannedWorkout.colorHex)),
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
                      ),
                    ),
                  ),
                  // 하단 버튼 (날짜 선택 시에만 표시)
                  if (selectedDay != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _planSelectedRoutinesForDate(
                                selectedRoutines,
                                selectedDay!,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: Text(
                              isSameDay(selectedDay!, DateTime.now())
                                  ? '오늘 운동 시작하기'
                                  : '${selectedDay!.month}월 ${selectedDay!.day}일에 계획하기',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// [Phase 2] 선택된 루틴들을 특정 날짜에 계획
  Future<void> _planSelectedRoutinesForDate(
    List<Routine> selectedRoutines,
    DateTime selectedDate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final normalizedSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isFutureDate = normalizedSelected.isAfter(normalizedToday);

    try {
      // 모든 루틴의 운동을 ExerciseBaseline 리스트로 변환
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final allBaselines = <ExerciseBaseline>[];
      for (final routine in selectedRoutines) {
        if (routine.routineItems == null) continue;
        for (final item in routine.routineItems!) {
          allBaselines.add(ExerciseBaseline(
            id: const Uuid().v4(),
            userId: userId,
            exerciseName: item.exerciseName,
            bodyPart: item.bodyPart,
            targetMuscles: const [],
            workoutSets: const [],
            routineId: routine.id,
            isHiddenFromHome: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      if (allBaselines.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('선택된 루틴에 운동이 없습니다.')),
        );
        return;
      }

      if (!isFutureDate) {
        // [Case A: 오늘] - 홈 화면에 추가 (DB 즉시 저장)
        await ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
          allBaselines,
          routineId: selectedRoutines.length == 1 ? selectedRoutines.first.id : null,
        );

        // 선택 초기화
        widget.onClearSelection();

        navigator.popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${allBaselines.length}개 운동이 홈 화면에 추가되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // [Case B: 미래 날짜] - planned_workouts 테이블에 저장
        final repository = ref.read(workoutRepositoryProvider);

        final plannedWorkouts = <PlannedWorkout>[];
        for (final baseline in allBaselines) {
          final persistedBaseline = await repository.ensureExerciseVisible(
            baseline.exerciseName,
            baseline.bodyPart?.code ?? 'full',
            [],
          );

          final plannedWorkout = PlannedWorkout(
            id: const Uuid().v4(),
            userId: userId,
            baselineId: persistedBaseline.id,
            scheduledDate: normalizedSelected,
            targetWeight: 0.0,
            targetReps: 0,
            targetSets: 1,
            exerciseName: baseline.exerciseName,
            isCompleted: false,
            isConvertedToLog: false,
            colorHex: '0xFF9C27B0', // 보라색 (루틴 계획)
            createdAt: DateTime.now(),
          );

          plannedWorkouts.add(plannedWorkout);
        }

        await repository.savePlannedWorkouts(plannedWorkouts);

        ref.read(plannedWorkoutsRefreshProvider.notifier).state++;

        // 선택 초기화
        widget.onClearSelection();

        navigator.popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${allBaselines.length}개 운동이 ${selectedDate.month}월 ${selectedDate.day}일에 계획되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('운동 계획 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesProvider);
    final isPremium = ref.watch(subscriptionProvider).isPremium;
    final isSelectionMode = widget.isSelectionMode;
    final selectedIds = widget.selectedRoutineIds;

    return routinesAsync.when(
      data: (routines) {
        // [Freemium] 생성일 기준 오래된 순으로 정렬 (첫 3개가 무료)
        // null인 경우 가장 최근으로 간주 (맨 뒤로)
        final sortedRoutines = List<Routine>.from(routines)
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.now();
            final bDate = b.createdAt ?? DateTime.now();
            return aDate.compareTo(bDate);
          });

        return Column(
          children: [
            // [Phase 2] "루틴 생성하기" 버튼: Management Mode에서만 표시
            if (!isSelectionMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // 3 Free Routines, then Premium required
                    onPressed: (isPremium || routines.length < 3)
                        ? () => _showCreateRoutineModal(context)
                        : () async {
                            final isPurchased = await showPremiumGuidanceDialog(context);
                            if (isPurchased == true && context.mounted) {
                              ref.invalidate(subscriptionProvider);
                              ref.invalidate(routinesProvider);
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('루틴 생성하기'),
                  ),
                ),
              ),
            // [Phase 2] 힌트 텍스트: Selection Mode에서만 표시
            if (isSelectionMode)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  '루틴을 선택하고 날짜를 지정하세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: sortedRoutines.isEmpty
                  ? const Center(
                      child: Text('저장된 루틴이 없습니다'),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            // 하단 버튼이 있을 때 여백 확보
                            bottom: (isSelectionMode && selectedIds.isNotEmpty) ? 130 : 16,
                          ),
                          itemCount: sortedRoutines.length,
                          itemBuilder: (context, index) {
                            final routine = sortedRoutines[index];
                            // [Freemium] 무료 사용자는 index 0, 1, 2만 접근 가능
                            final isLocked = !isPremium && index >= 3;

                            return _buildRoutineCard(
                              routine: routine,
                              isLocked: isLocked,
                              index: index,
                            );
                          },
                        ),
                        // [Phase 2] 하단 액션 바 (선택 모드 + 선택된 루틴이 있을 때)
                        if (isSelectionMode && selectedIds.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 메인 액션 버튼
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showSelectedRoutinesPlanSheet(sortedRoutines),
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(
                                          '${selectedIds.length}개 루틴 다시하기',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(48),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // 취소 버튼 - 선택 해제 후 화면 유지
                                    TextButton(
                                      onPressed: widget.onClearSelection,
                                      child: Text(
                                        '선택 해제',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('오류: $error'),
      ),
    );
  }

  /// [Freemium] 루틴 카드 빌드 (잠금 상태 지원)
  Widget _buildRoutineCard({
    required Routine routine,
    required bool isLocked,
    required int index,
  }) {
    final isSelectionMode = widget.isSelectionMode;
    final isSelected = widget.selectedRoutineIds.contains(routine.id);

    // [Phase 3] onTap 동작 결정
    VoidCallback? onTapAction;
    if (isLocked) {
      onTapAction = () => _showUpgradePrompt();
    } else if (isSelectionMode) {
      onTapAction = () => widget.onToggleSelection(routine.id);
    } else {
      // Management Mode: 카드 탭 시 옵션 시트 표시
      onTapAction = () => _showRoutineOptionsSheet(routine);
    }

    final cardContent = Card(
      key: ValueKey('routine_${routine.id}'),
      clipBehavior: Clip.antiAlias,
      // [Phase 3] Selection Mode에서 선택된 카드 배경색
      color: (isSelectionMode && isSelected && !isLocked)
          ? Colors.blue.withValues(alpha: 0.15)
          : null,
      child: InkWell(
        onTap: onTapAction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            // [Phase 3] Leading: 선택 모드에서는 체크박스, 관리 모드에서는 폴더 아이콘
            leading: isSelectionMode
                ? Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 28,
                  )
                : Icon(
                    Icons.folder_outlined,
                    color: isLocked ? Colors.grey : Colors.grey[600],
                    size: 24,
                  ),
            title: Text(
              routine.name,
              style: TextStyle(
                color: isLocked ? Colors.grey : null,
                fontWeight: (isSelectionMode && isSelected)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${routine.routineItems?.length ?? 0}개 운동',
              style: TextStyle(
                color: isLocked
                    ? Colors.grey[400]
                    : (isSelectionMode && isSelected)
                        ? Colors.blue[700]
                        : Colors.grey[600],
              ),
            ),
            // [Phase 3] Trailing: 잠금 아이콘만 표시 (3-dots 메뉴 제거)
            trailing: isLocked
                ? const Icon(Icons.lock, color: Colors.grey)
                : null,
          ),
        ),
      ),
    );

    // [Freemium] 잠금 상태 UI
    if (isLocked) {
      return Stack(
        children: [
          // 카드에 반투명 효과
          Opacity(
            opacity: 0.6,
            child: cardContent,
          ),
          // 프리미엄 배지 오버레이
          Positioned(
            top: 8,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return cardContent;
  }

  /// [Freemium] 프리미엄 업그레이드 안내 표시
  Future<void> _showUpgradePrompt() async {
    final isPurchased = await showPremiumGuidanceDialog(context);
    if (isPurchased == true && mounted) {
      ref.invalidate(subscriptionProvider);
      ref.invalidate(routinesProvider);
    }
  }

  /// 루틴 상세 페이지로 이동
  void _navigateToRoutineDetail(Routine routine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(routine: routine),
      ),
    );
  }

  /// 루틴 옵션 BottomSheet 표시 (3-dots 메뉴)
  void _showRoutineOptionsSheet(Routine routine) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
              // 루틴 이름 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  routine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // 저장된 운동 보기
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.blue),
                title: const Text('저장된 운동 보기'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoutineDetail(routine);
                },
              ),
              // 루틴 삭제
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '루틴 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRoutine(routine);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 루틴 삭제 (확인 다이얼로그 포함)
  ///
  /// 주의: 과거 운동 기록은 보존됩니다.
  /// 루틴 메타데이터만 삭제되며, 이 루틴으로 수행한 운동 기록은 유지됩니다.
  ///
  /// 부수 효과: 삭제 후 홈 화면에서 해당 루틴의 운동들이 "신규 운동" 그룹으로 이동합니다.
  /// (이는 오류가 아니라 자연스러운 현상입니다. routine_id가 null이 되었기 때문입니다.)
  Future<void> _deleteRoutine(Routine routine) async {
    // [안전 장치] 비동기 작업 전에 Messenger 객체를 미리 확보
    final messenger = ScaffoldMessenger.of(context);

    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${routine.name} 루틴을 정말 삭제하시겠습니까?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• 이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 과거 운동 기록은 보존됩니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    // 사용자가 취소를 누른 경우
    if (confirmed != true) return;

    try {
      // 루틴 삭제 실행 (과거 기록 보존)
      final repository = ref.read(workoutRepositoryProvider);
      await repository.deleteRoutine(routine.id);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // Provider 갱신 (UI 즉시 업데이트)
      ref.invalidate(routinesProvider);
      // [추가] 홈 화면도 갱신 (루틴 그룹 변경 반영)
      ref.invalidate(baselinesProvider);

      // 성공 메시지 표시
      messenger.showSnackBar(
        const SnackBar(
          content: Text('루틴이 삭제되었습니다. 과거 운동 기록은 보존되었습니다.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 오류 메시지 표시
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
