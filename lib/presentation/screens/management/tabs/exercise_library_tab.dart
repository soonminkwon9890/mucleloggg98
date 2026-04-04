import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/workout_colors.dart';
import '../../../../core/enums/exercise_enums.dart';
import '../../../../data/models/exercise_baseline.dart';
import '../../../../data/models/planned_workout.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import '../../../widgets/common/bottom_sheet_container.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../workout/workout_analysis_screen.dart';

/// 탭 1: 운동 보관함
class ExerciseLibraryTab extends ConsumerStatefulWidget {
  const ExerciseLibraryTab({super.key});

  @override
  ConsumerState<ExerciseLibraryTab> createState() => _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends ConsumerState<ExerciseLibraryTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  BodyPart _selectedBodyPart = BodyPart.upper;
  late TabController _tabController;

  // [Smart Search & Filter] 검색어 및 세부 부위 필터 상태
  String _searchQuery = '';
  String _selectedSubPart = '전체';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // 부위별 세부 필터 칩 목록
  static const Map<BodyPart, List<String>> _subPartChips = {
    BodyPart.upper: ['전체', '가슴', '등', '어깨', '이두', '삼두', '코어'],
    BodyPart.lower: ['전체', '대퇴사두(앞)', '햄스트링(뒤)', '둔근(힙)', '종아리'],
    BodyPart.full: ['전체'],
  };

  // [Legacy Compatibility] 구버전 데이터 매핑
  // 기존 DB에 '팔', '복근'으로 저장된 데이터를 새 필터로도 검색 가능하게 함
  static const Map<String, List<String>> _legacyMuscleMapping = {
    '이두': ['이두', '팔'],      // '이두' 필터 → '이두' 또는 '팔' 포함 시 매칭
    '삼두': ['삼두', '팔'],      // '삼두' 필터 → '삼두' 또는 '팔' 포함 시 매칭
    '코어': ['코어', '복근'],    // '코어' 필터 → '코어' 또는 '복근' 포함 시 매칭
  };

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
          // 탭 전환 시 세부 필터 초기화 (검색어는 유지)
          _selectedSubPart = '전체';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// [Smart Filter] 검색어 + 세부 부위 필터 적용 (Legacy 호환 포함)
  List<ExerciseBaseline> _filterBaselines(List<ExerciseBaseline> baselines) {
    return baselines.where((baseline) {
      // 1. 메인 부위 필터 (탭 기준)
      if (baseline.bodyPart != _selectedBodyPart) {
        return false;
      }

      // 2. 검색어 필터 (대소문자/공백 무시)
      final normalizedQuery = _searchQuery.replaceAll(' ', '').toLowerCase();
      final normalizedName = baseline.exerciseName.replaceAll(' ', '').toLowerCase();
      final matchesSearch = normalizedQuery.isEmpty || normalizedName.contains(normalizedQuery);

      if (!matchesSearch) {
        return false;
      }

      // 3. 세부 부위 필터 (MULTI-TARGET 지원 + Legacy 호환)
      if (_selectedSubPart == '전체') {
        return true;
      }

      // targetMuscles 리스트에서 선택된 세부 부위를 포함하는지 확인
      final targetMuscles = baseline.targetMuscles ?? [];

      // [Legacy Compatibility] 레거시 매핑이 있는 경우 해당 키워드들도 함께 검색
      final searchKeywords = _legacyMuscleMapping[_selectedSubPart] ?? [_selectedSubPart];

      final matchesSubPart = targetMuscles.any((muscle) {
        final normalizedMuscle = muscle.replaceAll(' ', '').toLowerCase();
        // 모든 검색 키워드 중 하나라도 매칭되면 true
        return searchKeywords.any((keyword) {
          final normalizedKeyword = keyword.replaceAll(' ', '').toLowerCase();
          // 부분 매칭: '대퇴사두(앞)' 필터가 '대퇴사두' 데이터와 매칭되도록
          return normalizedMuscle.contains(normalizedKeyword) ||
                 normalizedKeyword.contains(normalizedMuscle);
        });
      });

      return matchesSubPart;
    }).toList();
  }

  /// 검색어 클리어
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  /// 세부 부위 필터 선택
  void _selectSubPart(String subPart) {
    setState(() {
      _selectedSubPart = subPart;
    });
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
      confirmDelete = await ConfirmationDialog.show(
        context: context,
        title: '운동 삭제 경고',
        message: '이 운동은 다음 루틴에 포함되어 있습니다: $routineNames\n\n모두 삭제하시겠습니까?',
        confirmText: '삭제',
        confirmColor: Colors.red,
        useElevatedButton: true,
      );
    } else {
      // 루틴에 포함되어 있지 않으면 일반 확인 다이얼로그
      confirmDelete = await ConfirmationDialog.show(
        context: context,
        title: '운동 삭제 확인',
        message: '${baseline.exerciseName}을(를) 정말 삭제하시겠습니까?\n\n모든 기록이 삭제됩니다.',
        confirmText: '삭제',
        confirmColor: Colors.red,
        useElevatedButton: true,
      );
    }

    if (!confirmDelete || !mounted) return;

    // RPC 함수 호출
    try {
      await repository.deleteBaseline(baseline.id, baseline.exerciseName);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // Provider 갱신 (화면 즉시 업데이트) - C.3 중앙 집중화
      ref.invalidateExerciseWithRoutines();

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
    final selectionState = ref.read(selectionProvider);
    if (selectionState.selectedBaselineIds.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final baselines = ref.read(archivedBaselinesProvider).value ?? [];
    final selectedBaselines = baselines
        .where((b) => selectionState.selectedBaselineIds.contains(b.id))
        .toList();

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
    await BottomSheetContainer.show(
      context: context,
      maxHeightRatio: 2 / 3,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              children: [
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
                                color:
                                    Color(int.parse(plannedWorkout.colorHex)),
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
        // [Case A: 오늘/과거] - 기존 _addToToday 로직 사용 (DB 즉시 저장)
        await ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
              selectedBaselines,
              routineId: null,
              date: normalizedSelected,
            );

        // 선택 초기화 (via provider)
        ref.read(selectionProvider.notifier).clearBaselineSelection();

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
            targetReps: 0, // Manual: 빈 값
            targetSets: 1, // Manual: 기본 1세트
            exerciseName: baseline.exerciseName,
            isCompleted: false,
            isConvertedToLog: false,
            colorHex: WorkoutColors.manualAddHex, // 녹색 (수동 추가 구분)
            createdAt: DateTime.now(),
          );

          plannedWorkouts.add(plannedWorkout);
        }

        // 3. planned_workouts 테이블에 일괄 저장
        await repository.savePlannedWorkouts(plannedWorkouts);

        // 4. 캘린더 화면 갱신 트리거
        ref.read(plannedWorkoutsRefreshProvider.notifier).state++;

        // 선택 초기화 (via provider)
        ref.read(selectionProvider.notifier).clearBaselineSelection();

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

  /// [Smart Search & Filter] 검색창 위젯 빌드
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: '운동 이름으로 검색...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// [Smart Search & Filter] 세부 부위 필터 칩 빌드
  Widget _buildSubPartFilterChips() {
    final chips = _subPartChips[_selectedBodyPart] ?? ['전체'];

    // 전신 탭이거나 칩이 '전체' 하나뿐이면 칩 UI 숨김
    if (chips.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedSubPart == chip;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(chip),
              selected: isSelected,
              onSelected: (_) => _selectSubPart(chip),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primary,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    final baselinesAsync = ref.watch(archivedBaselinesProvider);

    // Watch selection state from provider
    final selectionState = ref.watch(selectionProvider);
    final isSelectionMode = selectionState.isSelectionMode;
    final selectedIds = selectionState.selectedBaselineIds;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: BodyPart.values
              .map((bodyPart) => Tab(text: bodyPart.label))
              .toList(),
        ),
        // [Smart Search & Filter] 검색창
        _buildSearchBar(),
        // [Smart Search & Filter] 세부 부위 필터 칩
        _buildSubPartFilterChips(),
        // [Phase 2] 헤더 영역: Selection Mode에서만 안내 텍스트 표시
        if (isSelectionMode)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
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

              // [Smart Search & Filter] 필터 결과 없음 처리
              if (filtered.isEmpty) {
                // 검색어나 필터가 있는 경우 다른 메시지 표시
                if (_searchQuery.isNotEmpty || _selectedSubPart != '전체') {
                  return FullScreenEmptyState(
                    icon: Icons.search_off,
                    title: '검색 결과가 없습니다',
                    subtitle: _searchQuery.isNotEmpty
                        ? '"$_searchQuery"에 해당하는 운동이 없습니다'
                        : '$_selectedSubPart 부위의 운동이 없습니다',
                  );
                }
                return const FullScreenEmptyState(
                  icon: Icons.fitness_center,
                  title: '해당 부위의 운동이 없습니다',
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
                      bottom: (isSelectionMode && selectedIds.isNotEmpty)
                          ? 130
                          : 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final baseline = filtered[index];
                      final isSelected = selectedIds.contains(baseline.id);
                      final targetMusclesText = (baseline.targetMuscles !=
                                  null &&
                              baseline.targetMuscles!.isNotEmpty)
                          ? baseline.targetMuscles!.join(', ')
                          : '부위 미설정';
                      final bodyPartLabel = baseline.bodyPart?.label;
                      final subtitleText =
                          (bodyPartLabel == null || bodyPartLabel.trim().isEmpty)
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
                              ? () => ref
                                  .read(selectionProvider.notifier)
                                  .toggleBaselineSelection(baseline.id)
                              : () => _showExerciseOptions(baseline),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              // [Phase 3] 선택 모드에서만 체크박스 표시
                              leading: isSelectionMode
                                  ? Icon(
                                      isSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color:
                                          isSelected ? Colors.blue : Colors.grey,
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
                                onPressed: () => ref
                                    .read(selectionProvider.notifier)
                                    .clearBaselineSelection(),
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
            loading: () => const FullScreenLoading(),
            error: (error, stack) => Center(
              child: Text('오류: $error'),
            ),
          ),
        ),
      ],
    );
  }
}
