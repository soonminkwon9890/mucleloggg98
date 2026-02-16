import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workout_provider.dart';
import '../subscription/subscription_screen.dart';
import '../workout/workout_analysis_screen.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/routine_item.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/enums/exercise_enums.dart';

/// 관리 페이지 (운동 보관함 및 루틴 관리)
class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        children: const [
          _ExerciseLibraryTab(),
          _RoutinesTab(),
        ],
      ),
    );
  }
}

/// 탭 1: 운동 보관함
class _ExerciseLibraryTab extends ConsumerStatefulWidget {
  const _ExerciseLibraryTab();

  @override
  ConsumerState<_ExerciseLibraryTab> createState() =>
      _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends ConsumerState<_ExerciseLibraryTab>
    with SingleTickerProviderStateMixin {
  BodyPart _selectedBodyPart = BodyPart.upper;
  final Set<String> _selectedBaselineIds = {};
  final Set<String> _expandedBaselineIds = {}; // 펼쳐진 운동 종목 추적
  bool _isSelectionMode = false;
  late TabController _tabController;
  // 더보기 상태 관리 (운동별로 관리)
  final Map<String, bool> _showAllDates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          final tabs = [BodyPart.upper, BodyPart.lower, BodyPart.full];
          _selectedBodyPart = tabs[_tabController.index];
          _selectedBaselineIds.clear();
          _expandedBaselineIds.clear();
          _isSelectionMode = false;
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

  void _handleLongPress(String baselineId) {
    setState(() {
      _isSelectionMode = true;
      _selectedBaselineIds.add(baselineId);
    });
  }

  void _toggleSelection(String baselineId) {
    setState(() {
      if (_selectedBaselineIds.contains(baselineId)) {
        _selectedBaselineIds.remove(baselineId);
        if (_selectedBaselineIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBaselineIds.add(baselineId);
      }
    });
  }

  /// 특정 날짜의 세트 기록을 오늘 날짜로 복사

  /// 보관함에서 오늘 운동에 추가 (메모리 전용 - DB 저장 X)
  /// addFromArchiveOrRoutine을 사용하여 데이터 리셋 후 홈 화면에 표시합니다.
  /// 실제 DB 저장은 사용자가 세트를 완료할 때 수행됩니다.
  void _addToToday() {
    if (_selectedBaselineIds.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    final baselines = ref.read(archivedBaselinesProvider).value ?? [];

    final selectedBaselines =
        baselines.where((b) => _selectedBaselineIds.contains(b.id)).toList();

    if (selectedBaselines.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('선택된 운동을 찾을 수 없습니다.')),
      );
      return;
    }

    // 메모리 전용 추가: 새 UUID 생성 + 데이터 리셋
    ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
      selectedBaselines,
      routineId: null, // 보관함에서 추가 시 routineId 없음
    );

    final addedCount = selectedBaselines.length;

    // 선택 모드 해제
    setState(() {
      _selectedBaselineIds.clear();
      _isSelectionMode = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('$addedCount개 운동을 오늘 목록에 추가했습니다.'),
      ),
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

  Future<void> _saveAsRoutine() async {
    if (_selectedBaselineIds.isEmpty) return;

    // Check routine limit: 3 free, then premium required
    final routines = ref.read(routinesProvider).valueOrNull ?? [];
    final isPremium = ref.read(subscriptionProvider).isPremium;

    if (!isPremium && routines.length >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('무료로 3개 루틴을 생성하셨습니다. 더 많은 루틴을 생성하려면 프리미엄이 필요합니다.'),
          action: SnackBarAction(
            label: '멤버십 보기',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 이름 입력'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '예: 상체 루틴',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
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
      final baselines = await repository.getBaselines();
      final selectedBaselines =
          baselines.where((b) => _selectedBaselineIds.contains(b.id)).toList();

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

      if (mounted) {
        // 루틴 목록 즉시 갱신 (루틴 관리 탭)
        ref.invalidate(routinesProvider);

        setState(() {
          _selectedBaselineIds.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(archivedBaselinesProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: BodyPart.values.map((bodyPart) => Tab(text: bodyPart.label)).toList(),
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
                  SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                      final baseline = filtered[index];
                      final isSelected =
                          _selectedBaselineIds.contains(baseline.id);
                      final targetMusclesText =
                          (baseline.targetMuscles != null &&
                                  baseline.targetMuscles!.isNotEmpty)
                              ? baseline.targetMuscles!.join(', ')
                              : '부위 미설정';
                      final bodyPartLabel = baseline.bodyPart?.label;
                      final subtitleText = (bodyPartLabel == null ||
                              bodyPartLabel.trim().isEmpty)
                          ? targetMusclesText
                          : '$bodyPartLabel · $targetMusclesText';

                      return Slidable(
                        key: ValueKey(baseline.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.55,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkoutAnalysisScreen(
                                      exerciseName: baseline.exerciseName,
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.history,
                              label: '운동 기록',
                              flex: 2,
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _confirmAndDeleteBaseline(baseline),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '삭제',
                              flex: 1,
                            ),
                          ],
                        ),
                        child: Card(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: _isSelectionMode
                              ? ListTile(
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleSelection(baseline.id),
                                  ),
                                  title: Text(baseline.exerciseName),
                                  subtitle: Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _toggleSelection(baseline.id),
                                )
                              : GestureDetector(
                                  onLongPress: () {
                                    _handleLongPress(baseline.id);
                                  },
                                  child: ExpansionTile(
                                    key: PageStorageKey(
                                        'exercise_${baseline.exerciseName}'),
                                    leading: baseline.thumbnailUrl != null &&
                                            baseline.thumbnailUrl!.isNotEmpty
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
                                                    size: 50);
                                              },
                                            ),
                                          )
                                        : const Icon(Icons.fitness_center,
                                            size: 50),
                                    title: Text(baseline.exerciseName),
                                    subtitle: Text(
                                      subtitleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.keyboard_double_arrow_left,
                                    ),
                                  initiallyExpanded: false,
                                  children: [
                                    // FutureBuilder로 날짜별 히스토리 비동기 로드
                                    FutureBuilder<
                                        Map<String, List<WorkoutSet>>>(
                                      future: ref
                                          .read(workoutRepositoryProvider)
                                          .getHistoryByExerciseName(
                                              baseline.exerciseName),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          );
                                        }
                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text('기록이 없습니다'),
                                          );
                                        }
                                        final history = snapshot.data!;

                                        // [Step 3] 날짜별 기록을 최신순으로 정렬하고, 최대 5개만 먼저 표시
                                        final sortedEntries = history.entries
                                            .toList()
                                          ..sort((a, b) =>
                                              b.key.compareTo(a.key)); // 최신순 정렬

                                        // 더보기 기능을 위한 상태 관리
                                        return StatefulBuilder(
                                          builder: (context, setState) {
                                            final showAll =
                                                _showAllDates[baseline.id] ??
                                                    false;
                                            final displayedEntries = showAll
                                                ? sortedEntries
                                                : sortedEntries
                                                    .take(5)
                                                    .toList();
                                            final hasMore =
                                                sortedEntries.length > 5;

                                            return Column(
                                              children: [
                                                // 날짜별 기록 리스트
                                                ...displayedEntries
                                                    .map((entry) {
                                                  final dateSets = entry.value;
                                                  final totalSets = dateSets
                                                      .length; // 실제 세트 개수

                                                  // 총 볼륨과 총 횟수 계산
                                                  final totalVolume = dateSets.fold<double>(
                                                    0.0,
                                                    (sum, set) => sum + (set.weight * set.reps),
                                                  );
                                                  final totalReps = dateSets.fold<int>(
                                                    0,
                                                    (sum, set) => sum + set.reps,
                                                  );

                                                  return ExpansionTile(
                                                    key: PageStorageKey(
                                                        'date_${baseline.exerciseName}_${entry.key}'),
                                                    initiallyExpanded: false,
                                                    title: Text(
                                                        '${entry.key} ($totalSets세트)'),
                                                    children: [
                                                      ListTile(
                                                        dense: true,
                                                        title: Text(
                                                          '총 볼륨: ${totalVolume.toStringAsFixed(1)}kg / 총 횟수: $totalReps회',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),

                                                // 더보기 버튼
                                                if (hasMore && !showAll)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          _showAllDates[baseline
                                                              .id] = true;
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.expand_more),
                                                      label: Text(
                                                          '더보기 (${sortedEntries.length - 5}개 더)'),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                  ),
                  if (!_isSelectionMode)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '길게 눌러 루틴으로 설정하거나 오늘 운동에 추가하세요.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_isSelectionMode && _selectedBaselineIds.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _addToToday,
                              icon: const Icon(Icons.add),
                              label: const Text('운동 다시하기'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _saveAsRoutine,
                              icon: const Icon(Icons.bookmark_add),
                              label: const Text('루틴으로 저장'),
                            ),
                          ],
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
  const _RoutinesTab();

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

      // Provider 갱신
      ref.invalidate(routinesProvider);

      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesProvider);
    final isPremium = ref.watch(subscriptionProvider).isPremium;

    return routinesAsync.when(
      data: (routines) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  // 3 Free Routines, then Premium required
                  onPressed: (isPremium || routines.length < 3)
                      ? () => _showCreateRoutineModal(context)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('무료로 3개 루틴을 생성하셨습니다. 더 많은 루틴을 생성하려면 프리미엄이 필요합니다.'),
                              action: SnackBarAction(
                                label: '멤버십 보기',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SubscriptionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('루틴 생성하기'),
                ),
              ),
            ),
            Expanded(
              child: routines.isEmpty
                  ? const Center(
                      child: Text('저장된 루틴이 없습니다'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: routines.length,
                      itemBuilder: (context, index) {
                        final routine = routines[index];
                        return Card(
                          child: ListTile(
                            title: Text(routine.name),
                            subtitle: Text(
                              '${routine.routineItems?.length ?? 0}개 운동',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              _showRoutineActionSheet(context, routine);
                            },
                          ),
                        );
                      },
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

  /// 루틴 액션 Bottom Sheet 표시
  void _showRoutineActionSheet(BuildContext context, Routine routine) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('운동 추가하기'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddExercisesToRoutineFlow(routine);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('운동 시작하기'),
                onTap: () {
                  Navigator.pop(context);
                  _startRoutine(routine);
                },
              ),
              // [추가] 구분선
              const Divider(),
              // [추가] 루틴 삭제 옵션 (빨간색)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  '루틴 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRoutine(routine);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 루틴에 운동 추가 플로우
  Future<void> _showAddExercisesToRoutineFlow(Routine routine) async {
    final messenger = ScaffoldMessenger.of(context);
    final selectedBaselineIds = <String>{};
    String selectedBodyPart = '상체';

    // 운동 선택 모달 표시
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
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('완료'),
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
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text('오류: $error'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 선택된 운동이 없으면 종료
    if (selectedBaselineIds.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('선택된 운동이 없습니다.')),
      );
      return;
    }

    // Repository를 통해 루틴에 운동 추가
    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.addExercisesToRoutine(
        routine.id,
        selectedBaselineIds.toList(),
      );

      // Provider 갱신
      ref.invalidate(routinesProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text('${selectedBaselineIds.length}개 운동이 루틴에 추가되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('운동 추가 오류: $e')),
      );
    }
  }

  /// 루틴 시작하기 - 메모리 전용 (DB 저장 X)
  /// addFromArchiveOrRoutine을 사용하여 데이터 리셋 후 홈 화면에 표시합니다.
  /// 실제 DB 저장은 사용자가 세트를 완료할 때 수행됩니다.
  void _startRoutine(Routine routine) {
    if (routine.routineItems == null || routine.routineItems!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴에 운동이 없습니다.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // RoutineItem을 ExerciseBaseline으로 변환 (데이터 리셋 상태)
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final now = DateTime.now();
    final baselines = routine.routineItems!.map((item) {
      return ExerciseBaseline(
        id: const Uuid().v4(), // 임시 ID (addFromArchiveOrRoutine에서 다시 생성됨)
        userId: userId,
        exerciseName: item.exerciseName,
        bodyPart: item.bodyPart,
        targetMuscles: const [], // RoutineItem에는 targetMuscles 없음
        workoutSets: const [], // 리셋: 빈 리스트
        routineId: null, // addFromArchiveOrRoutine에서 설정됨
        isHiddenFromHome: false,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // 메모리 전용 추가: 새 UUID 생성 + 데이터 리셋 + 루틴 ID 연결
    ref.read(homeViewModelProvider.notifier).addFromArchiveOrRoutine(
      baselines,
      routineId: routine.id, // 루틴 ID 전달
    );

    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${routine.routineItems!.length}개 운동이 홈 화면에 추가되었습니다.'),
      ),
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

      // Provider 갱신 (UI 즉시 업데이트)
      ref.invalidate(routinesProvider);
      // [추가] 홈 화면도 갱신 (루틴 그룹 변경 반영)
      ref.invalidate(baselinesProvider);

      // 성공 메시지 표시
      if (!mounted) return;
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
