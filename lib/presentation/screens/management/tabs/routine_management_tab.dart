import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/workout_colors.dart';
import '../../../../core/enums/exercise_enums.dart';
import '../../../../data/models/exercise_baseline.dart';
import '../../../../data/models/planned_workout.dart';
import '../../../../data/models/routine.dart';
import '../../../../data/models/routine_item.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../utils/premium_guidance_dialog.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/selectable_list_tile.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../routine_detail_screen.dart';

/// 탭 2: 나만의 루틴
class RoutineManagementTab extends ConsumerStatefulWidget {
  const RoutineManagementTab({super.key});

  @override
  ConsumerState<RoutineManagementTab> createState() =>
      _RoutineManagementTabState();
}

class _RoutineManagementTabState extends ConsumerState<RoutineManagementTab> {
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
                      final baselinesAsync =
                          ref.watch(archivedBaselinesProvider);
                      return baselinesAsync.when(
                        data: (baselines) {
                          final selectedBodyPartEnum =
                              BodyPartParsing.fromKorean(selectedBodyPart);
                          final filtered = baselines.where((baseline) {
                            return baseline.bodyPart == selectedBodyPartEnum;
                          }).toList();

                          if (filtered.isEmpty) {
                            return const FullScreenEmptyState(
                              icon: Icons.fitness_center,
                              title: '해당 부위의 운동이 없습니다',
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final baseline = filtered[index];
                              final isSelected =
                                  selectedBaselineIds.contains(baseline.id);

                              return SelectableImageListTile(
                                isSelected: isSelected,
                                onChanged: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      selectedBaselineIds.add(baseline.id);
                                    } else {
                                      selectedBaselineIds.remove(baseline.id);
                                    }
                                  });
                                },
                                title: baseline.exerciseName,
                                subtitle: (baseline.targetMuscles != null &&
                                        baseline.targetMuscles!.isNotEmpty)
                                    ? baseline.targetMuscles!.join(', ')
                                    : '부위 미설정',
                                imageUrl: baseline.thumbnailUrl,
                              );
                            },
                          );
                        },
                        loading: () => const FullScreenLoading(),
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

  /// 홈 화면에서 현재 선택된 날짜에 루틴을 즉시 추가
  Future<void> _addRoutinesToCurrentSelectedDate(List<Routine> allRoutines) async {
    final selectionState = ref.read(selectionProvider);
    final selectedIds = selectionState.selectedRoutineIds;
    if (selectedIds.isEmpty) return;

    final selectedRoutines =
        allRoutines.where((r) => selectedIds.contains(r.id)).toList();

    if (selectedRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택된 루틴을 찾을 수 없습니다.')),
      );
      return;
    }

    // 홈 화면에서 현재 선택된 날짜 사용 (캘린더 시트 생략)
    final selectedDate = ref.read(selectedHomeDateProvider);
    await _planSelectedRoutinesForDate(selectedRoutines, selectedDate);
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
        // [Case A: 오늘/과거] - 홈 화면에 추가 (DB 즉시 저장)
        await ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
              allBaselines,
              routineId: selectedRoutines.length == 1
                  ? selectedRoutines.first.id
                  : null,
              date: normalizedSelected,
            );

        // 선택 초기화 (via provider)
        ref.read(selectionProvider.notifier).clearRoutineSelection();

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
            colorHex: WorkoutColors.maintainHex, // 보라색 (루틴 계획)
            createdAt: DateTime.now(),
          );

          plannedWorkouts.add(plannedWorkout);
        }

        await repository.savePlannedWorkouts(plannedWorkouts);

        ref.read(plannedWorkoutsRefreshProvider.notifier).state++;

        // 선택 초기화 (via provider)
        ref.read(selectionProvider.notifier).clearRoutineSelection();

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

    // Watch selection state from provider
    final selectionState = ref.watch(selectionProvider);
    final isSelectionMode = selectionState.isSelectionMode;
    final selectedIds = selectionState.selectedRoutineIds;

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
                            final isPurchased =
                                await showPremiumGuidanceDialog(context);
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
                  '추가할 루틴을 선택하세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: sortedRoutines.isEmpty
                  ? const FullScreenEmptyState(
                      icon: Icons.folder_open,
                      title: '저장된 루틴이 없습니다',
                    )
                  : Stack(
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 메인 액션 버튼
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _addRoutinesToCurrentSelectedDate(
                                                sortedRoutines),
                                        icon: const Icon(Icons.add),
                                        label: Text(
                                          '${selectedIds.length}개 루틴 추가하기',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(48),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // 취소 버튼 - 선택 해제 후 화면 유지
                                    TextButton(
                                      onPressed: () => ref
                                          .read(selectionProvider.notifier)
                                          .clearRoutineSelection(),
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
      loading: () => const FullScreenLoading(),
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
    final selectionState = ref.watch(selectionProvider);
    final isSelectionMode = selectionState.isSelectionMode;
    final isSelected = selectionState.isRoutineSelected(routine.id);

    // [Phase 3] onTap 동작 결정
    VoidCallback? onTapAction;
    if (isLocked) {
      onTapAction = () => _showUpgradePrompt();
    } else if (isSelectionMode) {
      onTapAction = () =>
          ref.read(selectionProvider.notifier).toggleRoutineSelection(routine.id);
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
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  Future<void> _deleteRoutine(Routine routine) async {
    // [안전 장치] 비동기 작업 전에 Messenger 객체를 미리 확보
    final messenger = ScaffoldMessenger.of(context);

    // 확인 다이얼로그 표시
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: '루틴 삭제',
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
      confirmText: '삭제',
      confirmColor: Colors.red,
    );

    // 사용자가 취소를 누른 경우
    if (confirmed != true) return;

    try {
      // 루틴 삭제 실행 (과거 기록 보존)
      final repository = ref.read(workoutRepositoryProvider);
      await repository.deleteRoutine(routine.id);

      // [Fix] async gap 후 mounted 체크 필수
      if (!mounted) return;

      // Provider 갱신 (UI 즉시 업데이트) - C.3 중앙 집중화
      ref.invalidateRoutineData();

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
