import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/adaptive_widgets.dart';
import '../../providers/workout_provider.dart';
import '../../screens/workout/workout_analysis_screen.dart';
import 'workout_finish_dialog.dart';

/// 운동 카드 위젯 (AutomaticKeepAliveClientMixin 적용)
class WorkoutCard extends ConsumerStatefulWidget {
  final ExerciseBaseline baseline;
  final VoidCallback onUpdated;

  const WorkoutCard({
    super.key,
    required this.baseline,
    required this.onUpdated,
  });

  @override
  ConsumerState<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends ConsumerState<WorkoutCard>
    with AutomaticKeepAliveClientMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, WorkoutSet> _sets = {};
  
  // [추가] FocusNode 관리 (세트별 무게/횟수)
  final Map<String, FocusNode> _weightFocusNodes = {};
  final Map<String, FocusNode> _repsFocusNodes = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSets();
  }

  @override
  void didUpdateWidget(WorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // widget.baseline이 변경되었을 때 로컬 상태 동기화
    if (oldWidget.baseline.id != widget.baseline.id ||
        oldWidget.baseline.workoutSets != widget.baseline.workoutSets) {
      // 포커스가 있는 필드는 제외하고, _sets / _controllers 동기화
      _syncFromBaseline(widget.baseline);
    }
  }

  /// widget.baseline 기준으로 _sets, _controllers 동기화. 포커스 있는 필드는 스킵.
  void _syncFromBaseline(ExerciseBaseline baseline) {
    final sets = baseline.workoutSets ?? [];
    final today = DateTime.now();
    
    for (final set in sets) {
      // 오늘 날짜가 아니면 스킵
      if (set.createdAt == null || !DateFormatter.isSameDate(set.createdAt!, today)) {
        continue;
      }
      
      // 입력 중인 필드는 건드리지 않음
      if (_weightFocusNodes[set.id]?.hasFocus == true || 
          _repsFocusNodes[set.id]?.hasFocus == true) {
        continue;
      }
      
      _sets[set.id] = set;
      _controllers['weight_${set.id}']?.text = set.weight.toString();
      _controllers['reps_${set.id}']?.text = set.reps.toString();
      
      // FocusNode가 없으면 생성 (새로 추가된 세트)
      if (!_weightFocusNodes.containsKey(set.id)) {
        _weightFocusNodes[set.id] = FocusNode();
        _repsFocusNodes[set.id] = FocusNode();
        _weightFocusNodes[set.id]!.addListener(() => _onWeightFocusChange(set.id));
        _repsFocusNodes[set.id]!.addListener(() => _onRepsFocusChange(set.id));
      }
    }
    
    // baseline에 없는 세트 제거 (오늘 날짜가 아닌 세트는 제거하지 않음)
    final setIds = sets.where((s) => 
      s.createdAt != null && DateFormatter.isSameDate(s.createdAt!, today)
    ).map((s) => s.id).toSet();
    
    final toRemove = _sets.keys.where((id) => !setIds.contains(id)).toList();
    for (final id in toRemove) {
      _sets.remove(id);
      _controllers.remove('weight_$id')?.dispose();
      _controllers.remove('reps_$id')?.dispose();
      _weightFocusNodes[id]?.removeListener(() {});
      _weightFocusNodes[id]?.dispose();
      _repsFocusNodes[id]?.removeListener(() {});
      _repsFocusNodes[id]?.dispose();
      _weightFocusNodes.remove(id);
      _repsFocusNodes.remove(id);
    }
  }

  void _initializeSets() {
    // [중복 방지] 기존 세트 및 컨트롤러 완전히 제거
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    // FocusNode 정리
    for (final node in _weightFocusNodes.values) {
      node.removeListener(() {});
      node.dispose();
    }
    for (final node in _repsFocusNodes.values) {
      node.removeListener(() {});
      node.dispose();
    }
    _controllers.clear();
    _sets.clear();
    _weightFocusNodes.clear();
    _repsFocusNodes.clear();

    final today = DateTime.now();

    // 오늘 날짜의 세트만 필터링하여 새로 추가
    if (widget.baseline.workoutSets != null) {
      for (final set in widget.baseline.workoutSets!) {
        if (set.createdAt == null) continue;
        // 정확한 날짜 비교 (DateFormatter 사용)
        if (!DateFormatter.isSameDate(set.createdAt!, today)) {
          continue; // 오늘 날짜가 아니면 무시
        }
        _sets[set.id] = set;
        _controllers['weight_${set.id}'] =
            TextEditingController(text: set.weight.toString());
        _controllers['reps_${set.id}'] =
            TextEditingController(text: set.reps.toString());
        
        // [추가] FocusNode 생성 및 리스너 등록
        _weightFocusNodes[set.id] = FocusNode();
        _repsFocusNodes[set.id] = FocusNode();
        _weightFocusNodes[set.id]!.addListener(() => _onWeightFocusChange(set.id));
        _repsFocusNodes[set.id]!.addListener(() => _onRepsFocusChange(set.id));
      }
    }

    // 오늘 세트가 없으면 초기 세트 하나 생성
    if (_sets.isEmpty) {
      final newSet = WorkoutSet(
        id: const Uuid().v4(),
        baselineId: widget.baseline.id,
        weight: 0.0,
        reps: 0,
        sets: 1,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      _sets[newSet.id] = newSet;
      _controllers['weight_${newSet.id}'] = TextEditingController(text: '0');
      _controllers['reps_${newSet.id}'] = TextEditingController(text: '0');
      
      // [추가] FocusNode 생성 및 리스너 등록
      _weightFocusNodes[newSet.id] = FocusNode();
      _repsFocusNodes[newSet.id] = FocusNode();
      _weightFocusNodes[newSet.id]!.addListener(() => _onWeightFocusChange(newSet.id));
      _repsFocusNodes[newSet.id]!.addListener(() => _onRepsFocusChange(newSet.id));
    }
  }

  @override
  void dispose() {
    // FocusNode 정리
    for (final node in _weightFocusNodes.values) {
      node.removeListener(() {});
      node.dispose();
    }
    for (final node in _repsFocusNodes.values) {
      node.removeListener(() {});
      node.dispose();
    }
    _weightFocusNodes.clear();
    _repsFocusNodes.clear();
    
    // Controller 정리
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  // [추가] 포커스가 빠질 때만 ViewModel 업데이트 (깜빡임 방지 핵심)
  void _onWeightFocusChange(String setId) {
    final focusNode = _weightFocusNodes[setId];
    if (focusNode != null && !focusNode.hasFocus) {
      final controller = _controllers['weight_$setId'];
      if (controller != null) {
        final val = double.tryParse(controller.text);
        final currentSet = _sets[setId];
        if (currentSet != null && val != null && val != currentSet.weight) {
          // ViewModel 메모리 업데이트 (DB 호출 X)
          ref.read(homeViewModelProvider.notifier)
              .updateSetInMemory(setId, weight: val);
        }
      }
    }
  }

  void _onRepsFocusChange(String setId) {
    final focusNode = _repsFocusNodes[setId];
    if (focusNode != null && !focusNode.hasFocus) {
      final controller = _controllers['reps_$setId'];
      if (controller != null) {
        final val = int.tryParse(controller.text);
        final currentSet = _sets[setId];
        if (currentSet != null && val != null && val != currentSet.reps) {
          // ViewModel 메모리 업데이트 (DB 호출 X)
          ref.read(homeViewModelProvider.notifier)
              .updateSetInMemory(setId, reps: val);
        }
      }
    }
  }

  void _addSet() {
    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      baselineId: widget.baseline.id,
      weight: 0.0,
      reps: 0,
      sets: _sets.length + 1, // 세트 번호 자동 할당
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _sets[newSet.id] = newSet;
      _controllers['weight_${newSet.id}'] = TextEditingController(text: '0');
      _controllers['reps_${newSet.id}'] = TextEditingController(text: '0');
      
      // [추가] FocusNode 생성 및 리스너 등록
      _weightFocusNodes[newSet.id] = FocusNode();
      _repsFocusNodes[newSet.id] = FocusNode();
      _weightFocusNodes[newSet.id]!.addListener(() => _onWeightFocusChange(newSet.id));
      _repsFocusNodes[newSet.id]!.addListener(() => _onRepsFocusChange(newSet.id));
    });
  }

  /// 현재 카드의 총 볼륨 계산 (로컬 상태 _sets 기준)
  double _calculateCardTotalVolume() {
    double total = 0.0;
    for (final set in _sets.values) {
      final weight = double.tryParse(_controllers['weight_${set.id}']?.text ?? '0') ?? 0.0;
      final reps = int.tryParse(_controllers['reps_${set.id}']?.text ?? '0') ?? 0;
      total += weight * reps;
    }
    return total;
  }

  Future<void> _saveWorkoutCard() async {
    if (!mounted) return;

    // [추가] 다이얼로그 표시 전 총 볼륨 계산 (현재 카드의 세트들만)
    final totalVolume = _calculateCardTotalVolume();
    
    // [추가] 다이얼로그 표시
    final difficulty = await showDialog<String>(
      context: context,
      builder: (context) => WorkoutFinishDialog(
        totalVolume: totalVolume,
      ),
    );

    if (difficulty == null) return; // 취소 시 저장 중단

    try {
      final repository = ref.read(workoutRepositoryProvider);

      // [추가] 세션 정보 저장 (baseline_id 포함)
      await repository.saveWorkoutSession(
        baselineId: widget.baseline.id,
        date: DateTime.now(),
        difficulty: difficulty,
        totalVolume: totalVolume,
      );

      // 1. 데이터 저장 (일괄 처리) - 모든 세트를 isCompleted = true로 강제 설정
      // [Phase 3.1] 루프 내 개별 저장 → batchSaveWorkoutSets로 변경
      final setsToSave = <WorkoutSet>[];
      int setIndex = 0;
      for (final set in _sets.values) {
        setIndex++;
        final weight =
            double.tryParse(_controllers['weight_${set.id}']?.text ?? '0') ??
                0.0;
        final reps =
            int.tryParse(_controllers['reps_${set.id}']?.text ?? '0') ?? 0;
        
        // [핵심 수정] sets 필드를 인덱스 기반으로 명시적으로 할당 (1, 2, 3...)
        // 컨트롤러에서 파싱하지 않고 순서대로 할당하여 정확성 보장
        final setsCount = setIndex;

        // [핵심] isCompleted를 무조건 true로 설정하여 보관함 필터 통과
        // [중요] 저장 버튼을 눌렀을 때만 완료 처리 (불러온 직후에는 false 상태 유지)
        final completedSet = set.copyWith(
          weight: weight,
          reps: reps,
          sets: setsCount, // 인덱스 기반 세트 번호 (1부터 시작)
          isCompleted: true, // [저장 시점에만] Smart Delete 보호 & 보관함 표시를 위해 반드시 true
        );

        setsToSave.add(completedSet);
        
        // 로컬 상태도 업데이트하여 UI 일관성 유지
        setState(() {
          _sets[set.id] = completedSet;
        });
      }

      // [최적화] 일괄 저장 (네트워크 요청 1회)
      if (setsToSave.isNotEmpty) {
        await repository.batchSaveWorkoutSets(setsToSave);
      }

      // 2. 상태 갱신 (순서 중요)
      ref.invalidate(baselinesProvider); // 홈 화면 갱신
      ref.invalidate(workoutDatesProvider); // 캘린더 갱신

      // [핵심] 보관함 데이터 즉시 리로드 & 대기 (refresh 사용)
      final _ = await ref.refresh(archivedBaselinesProvider.future);

      if (!mounted) return;

      // 3. UI 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 저장되었습니다.')),
      );

      // 콜백 호출 (홈 화면에서 카드 제거)
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 오류: $e')),
      );
    }
  }

  Future<void> _deleteSet(String setId) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(workoutRepositoryProvider).deleteWorkoutSet(setId);

      setState(() {
        _controllers.remove('weight_$setId')?.dispose();
        _controllers.remove('reps_$setId')?.dispose();
        _controllers.remove('sets_$setId')?.dispose();
        _sets.remove(setId);
        
        // [추가] FocusNode 정리
        _weightFocusNodes[setId]?.removeListener(() {});
        _weightFocusNodes[setId]?.dispose();
        _repsFocusNodes[setId]?.removeListener(() {});
        _repsFocusNodes[setId]?.dispose();
        _weightFocusNodes.remove(setId);
        _repsFocusNodes.remove(setId);
      });

      // Provider 갱신 (홈 화면과 보관함 모두 갱신)
      ref.invalidate(baselinesProvider);
      ref.invalidate(archivedBaselinesProvider);

      messenger.showSnackBar(const SnackBar(content: Text('세트가 삭제되었습니다.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('세트 삭제 오류: $e')));
    }
  }

  Future<void> _deleteWorkoutCard() async {
    // 확인 다이얼로그 표시 (플랫폼별 적응형)
    final confirm = await AdaptiveWidgets.showAdaptiveDialog<bool>(
      context: context,
      title: '오늘 기록 삭제',
      content: '홈 화면 목록에서 제거하시겠습니까?\n(작성된 기록은 보관함에 안전하게 유지되며, 오늘 다시 추가하면 기록을 이어갈 수 있습니다.)',
      confirmText: '삭제',
      cancelText: '취소',
      destructive: true,
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      // [수정] ViewModel 메서드 호출 (Repository 직접 호출 제거)
      await ref.read(homeViewModelProvider.notifier).deleteWorkout(widget.baseline.id);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('오늘 기록이 삭제되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('삭제 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.baseline.exerciseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteWorkoutCard,
                  tooltip: '오늘 기록 삭제',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    // 로컬 상태에서 완료된 세트가 하나라도 있는지 확인
                    final hasCompletedSets =
                        _sets.values.any((set) => set.isCompleted);

                    if (!hasCompletedSets) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('저장된 기록이 없습니다. 운동을 수행하고 저장해 주세요.'),
                        ),
                      );
                      return;
                    }

                    // 저장된 운동만 상세 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutAnalysisScreen(
                          exerciseName: widget.baseline.exerciseName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 세트 입력 필드
            ..._sets.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final setId = entry.value.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // 세트 번호 표시 (읽기 전용)
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${index + 1}세트',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controllers['weight_$setId'],
                        focusNode: _weightFocusNodes[setId],
                        decoration: const InputDecoration(
                          labelText: '무게 (kg)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onEditingComplete: () => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controllers['reps_$setId'],
                        focusNode: _repsFocusNodes[setId],
                        decoration: const InputDecoration(
                          labelText: '횟수',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onEditingComplete: () => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _deleteSet(setId),
                      tooltip: '세트 삭제',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // 버튼 영역
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('세트 추가'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveWorkoutCard,
                    child: const Text('기록 저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
