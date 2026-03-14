import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/routine_item.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../core/enums/exercise_enums.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/selectable_list_tile.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/workout/reorder_workout_dialog.dart';

/// 루틴 상세 페이지
/// - 루틴 이름 수정 (AppBar)
/// - 볼륨 차트 (루틴 수행 기록)
/// - 운동 목록 (3-dots 메뉴로 삭제 가능)
/// - 운동 추가 버튼
class RoutineDetailScreen extends ConsumerStatefulWidget {
  final Routine routine;

  const RoutineDetailScreen({
    super.key,
    required this.routine,
  });

  @override
  ConsumerState<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  // 루틴 상태 (수정 반영용)
  late Routine _routine;

  // 이름 수정 관련 상태
  bool _isEditingName = false;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  bool _isUpdatingName = false;
  bool _hasShownDialog = false;

  // 차트 데이터
  List<FlSpot>? _chartSpots;
  Map<int, String>? _xAxisLabels;
  bool _isLoadingChart = false;
  double? _totalVolume;
  int? _executionCount;

  // [Phase 2] 타겟 근육 목록 (중복 제거된)
  List<String> _targetMuscles = [];

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _nameController = TextEditingController(text: _routine.name);
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onFocusChange);
    _loadChartData();
    _loadTargetMuscles(); // [Phase 2] 타겟 근육 로드
  }

  /// [Phase 2] 루틴 내 운동들의 타겟 근육 로드 (중복 제거)
  Future<void> _loadTargetMuscles() async {
    final items = _routine.routineItems ?? [];
    if (items.isEmpty) {
      setState(() => _targetMuscles = []);
      return;
    }

    try {
      // 보관함에서 모든 baseline 가져오기
      final baselines = await ref.read(archivedBaselinesProvider.future);

      // 루틴 내 운동 이름들로 baseline 매칭
      final exerciseNames = items.map((i) => i.exerciseName).toSet();

      // 매칭되는 baseline들의 targetMuscles 수집
      final allMuscles = <String>{};
      for (final baseline in baselines) {
        if (exerciseNames.contains(baseline.exerciseName)) {
          final muscles = baseline.targetMuscles ?? [];
          allMuscles.addAll(muscles.where((m) => m.trim().isNotEmpty));
        }
      }

      setState(() {
        _targetMuscles = allMuscles.toList()..sort(); // 가나다순 정렬
      });
    } catch (e) {
      // 에러 시 빈 목록으로 설정
      setState(() => _targetMuscles = []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.removeListener(_onFocusChange);
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// 포커스 변경 감지 - 포커스 해제 시 확인 다이얼로그 표시
  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName && !_hasShownDialog) {
      _showNameChangeConfirmation();
    }
  }

  /// 이름 수정 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditingName = !_isEditingName;
      _hasShownDialog = false;
      if (_isEditingName) {
        _nameController.text = _routine.name;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _nameFocusNode.requestFocus();
          }
        });
      }
    });
  }

  /// 이름 변경 확인 다이얼로그 표시
  Future<void> _showNameChangeConfirmation() async {
    if (_hasShownDialog) return;
    _hasShownDialog = true;

    final newName = _nameController.text.trim();

    if (newName.isEmpty || newName == _routine.name) {
      setState(() {
        _isEditingName = false;
        _nameController.text = _routine.name;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('이름 변경'),
        content: Text('"$newName"(으)로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateRoutineName(newName);
    } else {
      setState(() {
        _isEditingName = false;
        _nameController.text = _routine.name;
      });
    }
  }

  /// 루틴 이름 업데이트
  Future<void> _updateRoutineName(String newName) async {
    if (_isUpdatingName) return;

    setState(() => _isUpdatingName = true);

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.updateRoutineName(_routine.id, newName);

      setState(() {
        _routine = _routine.copyWith(name: newName);
        _isEditingName = false;
      });

      // Provider 갱신
      ref.invalidate(routinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴 이름이 변경되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이름 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingName = false);
    }
  }

  /// 차트 데이터 로드 (루틴 수행 기록)
  Future<void> _loadChartData() async {
    setState(() => _isLoadingChart = true);

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final history = await repository.getRoutineExecutionHistory(_routine.id);

      if (history.isEmpty) {
        setState(() {
          _chartSpots = null;
          _xAxisLabels = null;
          _totalVolume = 0;
          _executionCount = 0;
          _isLoadingChart = false;
        });
        return;
      }

      // 날짜별 볼륨 계산
      final volumeByDate = <String, double>{};
      double totalVol = 0;

      for (final entry in history.entries) {
        final dateKey = entry.key;
        final baselines = entry.value;

        double dayVolume = 0;
        for (final baseline in baselines) {
          for (final set in baseline.workoutSets ?? []) {
            dayVolume += set.weight * set.reps;
          }
        }
        volumeByDate[dateKey] = dayVolume;
        totalVol += dayVolume;
      }

      // 날짜순 정렬
      final sortedDates = volumeByDate.keys.toList()..sort();

      final spots = <FlSpot>[];
      final labels = <int, String>{};

      for (int i = 0; i < sortedDates.length; i++) {
        final dateKey = sortedDates[i];
        final volume = volumeByDate[dateKey]!;
        spots.add(FlSpot(i.toDouble(), volume));

        final date = DateTime.parse(dateKey);
        labels[i] = DateFormatter.formatChartLabel(date);
      }

      setState(() {
        _chartSpots = spots;
        _xAxisLabels = labels;
        _totalVolume = totalVol;
        _executionCount = sortedDates.length;
        _isLoadingChart = false;
      });
    } catch (e) {
      setState(() {
        _chartSpots = null;
        _xAxisLabels = null;
        _isLoadingChart = false;
      });
    }
  }

  /// 운동 삭제
  Future<void> _removeExercise(RoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text('${item.exerciseName}을(를) 루틴에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.removeExerciseFromRoutine(item.id);

      // 로컬 상태 업데이트
      setState(() {
        final updatedItems = _routine.routineItems
            ?.where((i) => i.id != item.id)
            .toList();
        _routine = _routine.copyWith(routineItems: updatedItems);
      });

      // Provider 갱신
      ref.invalidate(routinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.exerciseName}이(가) 삭제되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// [Phase 4] 운동 순서 변경 다이얼로그 표시
  Future<void> _showReorderDialog() async {
    final items = _routine.routineItems ?? [];
    if (items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('순서를 변경하려면 2개 이상의 운동이 필요합니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // RoutineItem을 ExerciseBaseline으로 변환 (다이얼로그 호환용)
    final baselines = items.map((item) {
      return ExerciseBaseline(
        id: item.id,
        userId: '',
        exerciseName: item.exerciseName,
        bodyPart: item.bodyPart,
        targetMuscles: const [],
        workoutSets: const [],
        isHiddenFromHome: false,
      );
    }).toList();

    showReorderWorkoutDialog(
      context,
      baselines,
      (reorderedList) async {
        // 순서가 변경되었는지 확인
        bool hasChanged = false;
        for (int i = 0; i < reorderedList.length; i++) {
          if (reorderedList[i].id != items[i].id) {
            hasChanged = true;
            break;
          }
        }

        if (!hasChanged) return;

        // DB에 새로운 순서 저장
        try {
          final repository = ref.read(workoutRepositoryProvider);
          final newOrder = reorderedList.map((b) => b.id).toList();
          await repository.updateRoutineItemOrder(_routine.id, newOrder);

          // 로컬 상태 업데이트: 새로운 순서에 맞게 routineItems 재정렬
          final reorderedItems = <RoutineItem>[];
          for (final baseline in reorderedList) {
            final originalItem = items.firstWhere((i) => i.id == baseline.id);
            reorderedItems.add(originalItem);
          }

          setState(() {
            _routine = _routine.copyWith(routineItems: reorderedItems);
          });

          // Provider 갱신
          ref.invalidate(routinesProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('순서가 변경되었습니다.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('순서 변경 실패: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  /// 운동 추가 모달 표시
  Future<void> _showAddExerciseModal() async {
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
                AppBar(
                  title: const Text('운동 선택'),
                  automaticallyImplyLeading: false,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('완료'),
                    ),
                  ],
                ),
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
                            setModalState(() => selectedBodyPart = part);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
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
                              final isSelected = selectedBaselineIds.contains(baseline.id);

                              return SelectableListTile(
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
                                title: Text(baseline.exerciseName),
                                subtitle: Text(
                                  (baseline.targetMuscles != null && baseline.targetMuscles!.isNotEmpty)
                                      ? baseline.targetMuscles!.join(', ')
                                      : '부위 미설정',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const FullScreenLoading(),
                        error: (error, stack) => Center(child: Text('오류: $error')),
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

    if (selectedBaselineIds.isEmpty) return;

    // 운동 추가 실행
    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.addExercisesToRoutine(
        _routine.id,
        selectedBaselineIds.toList(),
      );

      // 루틴 다시 로드
      final updatedRoutine = await repository.getRoutineById(_routine.id);
      if (updatedRoutine != null) {
        setState(() => _routine = updatedRoutine);
      }

      // Provider 갱신
      ref.invalidate(routinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedBaselineIds.length}개 운동이 추가되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('운동 추가 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditingName
            ? TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '루틴 이름 입력',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                onSubmitted: (_) => _showNameChangeConfirmation(),
              )
            : Text(_routine.name),
        actions: [
          if (_isUpdatingName)
            const Padding(
              padding: EdgeInsets.all(16),
              child: ButtonLoadingIndicator(size: 20),
            )
          else
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(_isEditingName ? '취소' : '이름 수정'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final repository = ref.read(workoutRepositoryProvider);
          final updatedRoutine = await repository.getRoutineById(_routine.id);
          if (updatedRoutine != null) {
            setState(() => _routine = updatedRoutine);
          }
          await _loadChartData();
          await _loadTargetMuscles(); // [Phase 2] 타겟 근육도 새로고침
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 요약 카드
              _buildSummaryCard(),
              const SizedBox(height: 16),

              // 볼륨 차트
              _buildVolumeChart(),
              const SizedBox(height: 16),

              // 운동 목록 헤더 (순서 변경 + 운동 추가 버튼)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '저장된 운동 (${_routine.routineItems?.length ?? 0}개)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // [Phase 4] 순서 변경 버튼
                      TextButton.icon(
                        onPressed: _showReorderDialog,
                        icon: const Icon(Icons.swap_vert, size: 18),
                        label: const Text('순서 변경'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      // 운동 추가 버튼
                      TextButton.icon(
                        onPressed: _showAddExerciseModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('운동 추가'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 운동 목록
              _buildExerciseList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 요약 카드 빌드
  Widget _buildSummaryCard() {
    final items = _routine.routineItems ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.fitness_center,
                  label: '운동 수',
                  value: '${items.length}개',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  icon: Icons.repeat,
                  label: '수행 횟수',
                  value: '${_executionCount ?? 0}회',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  icon: Icons.bar_chart,
                  label: '총 볼륨',
                  value: _totalVolume != null
                      ? '${(_totalVolume! / 1000).toStringAsFixed(1)}t'
                      : '-',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // [Phase 2] 타겟 근육 표시 (중복 제거됨)
            if (_targetMuscles.isEmpty)
              Text(
                '타겟 근육 정보 없음',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '타겟 근육',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _targetMuscles.map((muscle) {
                      return Chip(
                        label: Text(muscle),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 볼륨 차트 빌드
  Widget _buildVolumeChart() {
    if (_isLoadingChart) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: FullScreenLoading(),
        ),
      );
    }

    if (_chartSpots == null || _chartSpots!.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.bar_chart,
        title: '아직 수행 기록이 없습니다',
      );
    }

    final spots = _chartSpots!;
    const minX = 0.0;
    final maxX = (spots.length - 1).toDouble();

    // X축 라벨 간격 계산
    int interval = 1;
    if (spots.length > 10) {
      interval = (spots.length / 5).ceil();
    } else if (spots.length > 5) {
      interval = 2;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '볼륨 추이',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: const FlDotData(show: true),
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value / 1000).toStringAsFixed(0)}t',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: interval.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || _xAxisLabels?[index] == null) {
                            return const Text('');
                          }
                          return Text(
                            _xAxisLabels![index]!,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          final dateIndex = spot.x.toInt();
                          final dateLabel = _xAxisLabels?[dateIndex] ?? '';
                          return LineTooltipItem(
                            '$dateLabel: ${(spot.y / 1000).toStringAsFixed(1)}t',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 운동 목록 빌드
  Widget _buildExerciseList() {
    final items = _routine.routineItems ?? [];

    if (items.isEmpty) {
      return EmptyStateCard(
        icon: Icons.fitness_center,
        title: '루틴에 운동이 없습니다',
        actionLabel: '운동 추가하기',
        onAction: _showAddExerciseModal,
      );
    }

    return Column(
      children: items.map((item) {
        return Card(
          key: ValueKey('routine_item_${item.id}'),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(
              Icons.fitness_center,
              color: Colors.grey[600],
              size: 24,
            ),
            title: Text(
              item.exerciseName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(item.bodyPart?.label ?? '미분류'),
            // 3-dots 메뉴 버튼
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showExerciseOptionsSheet(item),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 운동 옵션 BottomSheet 표시 (3-dots 메뉴)
  void _showExerciseOptionsSheet(RoutineItem item) {
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
                  item.exerciseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // 삭제
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '루틴에서 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeExercise(item);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
