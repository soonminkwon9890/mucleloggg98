import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/enums/exercise_enums.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/workout_provider.dart';
import 'workout_finish_dialog.dart';

/// 저장 완료 시 호출되는 콜백: (저장 반영된 baseline, 기존 draft id)
typedef OnWorkoutUpdated = void Function(
  ExerciseBaseline? savedItem,
  String? oldId,
);

/// 운동 카드 위젯 (AutomaticKeepAliveClientMixin 적용)
class WorkoutCard extends ConsumerStatefulWidget {
  final ExerciseBaseline baseline;
  final OnWorkoutUpdated onUpdated;

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

  /// 로컬 데이터가 Dirty 상태인지 판단 (세트 추가 또는 입력값 존재)
  /// [Fix] TextEditingController의 실제 값을 확인 (_sets는 포커스 해제 전까지 업데이트 안 됨)
  bool get _isLocalDirty {
    // 조건 1: 세트가 2개 이상 (세트 추가됨)
    if (_sets.length > 1) return true;

    // 조건 2: Controller에 0이 아닌 입력값이 있는지 확인
    for (final setId in _sets.keys) {
      final weightText = _controllers['weight_$setId']?.text.trim() ?? '0';
      final repsText = _controllers['reps_$setId']?.text.trim() ?? '0';

      final weight = double.tryParse(weightText) ?? 0.0;
      final reps = int.tryParse(repsText) ?? 0;

      if (weight > 0 || reps > 0) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeSets();
  }

  @override
  void didUpdateWidget(WorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Guard Clause: 로컬 데이터가 소중하고(Dirty), 들어온 데이터가 초기 상태라면 동기화 차단
    if (_isLocalDirty) {
      final incomingSets = widget.baseline.workoutSets ?? [];
      // 들어온 데이터가 초기 상태인지 확인 (1세트 & 무게 0)
      final isIncomingInitialState = incomingSets.length == 1 &&
          incomingSets.first.weight == 0 &&
          incomingSets.first.reps == 0;

      if (isIncomingInitialState) {
        // 동기화 차단: _syncFromBaseline을 호출하지 않고 종료
        return;
      }
    }

    // widget.baseline이 변경되었을 때 로컬 상태 동기화
    if (oldWidget.baseline.id != widget.baseline.id ||
        oldWidget.baseline.workoutSets != widget.baseline.workoutSets) {
      // 포커스가 있는 필드는 제외하고, _sets / _controllers 동기화
      _syncFromBaseline(widget.baseline);
    }
  }

  /// widget.baseline 기준으로 _sets, _controllers 동기화. 포커스 있는 필드는 스킵.
  /// [방어 로직] 이미 해당 Set ID의 컨트롤러가 있으면 텍스트를 덮어쓰지 않음 (다른 카드 입력값 보존).
  void _syncFromBaseline(ExerciseBaseline baseline) {
    final sets = baseline.workoutSets ?? [];
    final today = DateTime.now();

    for (final set in sets) {
      // 오늘 날짜가 아니면 스킵
      if (set.createdAt == null ||
          !DateFormatter.isSameDate(set.createdAt!, today)) {
        continue;
      }

      // 입력 중인 필드는 건드리지 않음
      if (_weightFocusNodes[set.id]?.hasFocus == true ||
          _repsFocusNodes[set.id]?.hasFocus == true) {
        continue;
      }

      // 방어 로직: 컨트롤러가 이미 존재하는 경우에만 수행
      final weightKey = 'weight_${set.id}';
      final repsKey = 'reps_${set.id}';
      if (_controllers.containsKey(weightKey) && _controllers.containsKey(repsKey)) {
        final weightController = _controllers[weightKey]!;
        final repsController = _controllers[repsKey]!;

        // 로컬에 값이 있는데 서버에서 0이 들어오면 건드리지 않음 (Draft 보존)
        final localHasValue = weightController.text.isNotEmpty || repsController.text.isNotEmpty;
        final serverIsZero = set.weight == 0 || set.reps == 0;

        if (localHasValue && serverIsZero) {
          continue; // controller 업데이트와 _sets 갱신을 스킵
        }
      }

      _sets[set.id] = set;

      // 컨트롤러가 없을 때만 생성 및 초기 텍스트 설정 (있으면 덮어쓰지 않음)
      if (!_controllers.containsKey('weight_${set.id}')) {
        _controllers['weight_${set.id}'] =
            TextEditingController(text: set.weight.toString());
        _controllers['reps_${set.id}'] =
            TextEditingController(text: set.reps.toString());
        _weightFocusNodes[set.id] = FocusNode();
        _repsFocusNodes[set.id] = FocusNode();
        _weightFocusNodes[set.id]!
            .addListener(() => _onWeightFocusChange(set.id));
        _repsFocusNodes[set.id]!
            .addListener(() => _onRepsFocusChange(set.id));
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
    // [Critical Fix] 상태 파괴 전 모든 pending 입력값을 HomeViewModel에 동기화
    // 다른 카드 저장으로 인한 rebuild 시 이 카드의 Draft 입력값을 보존
    _syncPendingInputsToViewModel();

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

  /// [Critical] 모든 pending 입력값을 HomeViewModel에 동기화
  /// dispose() 호출 전에 실행하여 다른 카드 저장 시 이 카드의 Draft가 유실되지 않도록 함
  void _syncPendingInputsToViewModel() {
    for (final entry in _sets.entries) {
      final setId = entry.key;
      final currentSet = entry.value;

      final weightController = _controllers['weight_$setId'];
      final repsController = _controllers['reps_$setId'];

      // Controller에서 현재 값 추출
      final weightText = weightController?.text.trim() ?? '0';
      final repsText = repsController?.text.trim() ?? '0';
      final parsedWeight = double.tryParse(weightText) ?? 0.0;
      final parsedReps = int.tryParse(repsText) ?? 0;

      // Upsert: 세트가 ViewModel에 없으면 추가, 있으면 업데이트
      ref.read(homeViewModelProvider.notifier).upsertSetInMemory(
        widget.baseline.id,
        setId,
        weight: parsedWeight,
        reps: parsedReps,
        sets: currentSet.sets,
        createdAt: currentSet.createdAt ?? DateTime.now(),
      );
    }
  }

  // 포커스가 빠질 때 ViewModel 업데이트 + 빈 입력 시 '0' 복구 (Handle Empty Input on Blur)
  void _onWeightFocusChange(String setId) {
    final focusNode = _weightFocusNodes[setId];
    if (focusNode != null && !focusNode.hasFocus) {
      final controller = _controllers['weight_$setId'];
      if (controller != null) {
        final trimmed = controller.text.trim();
        if (trimmed.isEmpty) {
          controller.text = '0';
        }
        final val = double.tryParse(controller.text);
        final currentSet = _sets[setId];
        if (currentSet != null && val != null && val != currentSet.weight) {
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
        final trimmed = controller.text.trim();
        if (trimmed.isEmpty) {
          controller.text = '0';
        }
        final val = int.tryParse(controller.text);
        final currentSet = _sets[setId];
        if (currentSet != null && val != null && val != currentSet.reps) {
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

      // [메모리→DB 동기화] 베이스라인이 DB에 없을 수 있으므로 먼저 확보
      // ensureExerciseVisible은 기존 레코드가 있으면 활성화, 없으면 생성
      final persistedBaseline = await repository.ensureExerciseVisible(
        widget.baseline.exerciseName,
        widget.baseline.bodyPart?.code ?? 'full',
        widget.baseline.targetMuscles ?? const [],
      );
      final baselineId = persistedBaseline.id;

      // [추가] 세션 정보 저장 (DB에 확보된 baseline_id 사용)
      await repository.saveWorkoutSession(
        baselineId: baselineId,
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
        // [메모리→DB 동기화] baselineId를 DB에 확보된 ID로 덮어씀
        final completedSet = set.copyWith(
          baselineId: baselineId, // DB에 확보된 baseline_id 사용
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

      // [Fix] async gap 후 mounted 체크 필수 (ConsumerStatefulElement._assertNotDisposed 방지)
      if (!mounted) return;

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

      // 부분 업데이트: 저장 반영된 baseline으로 해당 카드만 교체 (전체 새로고침 없음)
      final fullBaseline =
          await repository.getBaselineById(persistedBaseline.id);
      widget.onUpdated(
        fullBaseline ?? persistedBaseline,
        widget.baseline.id,
      );
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

      // [Fix] async gap 후 mounted 체크 필수 (setState 및 ref 사용 전)
      if (!mounted) return;

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

  /// 삭제 확인 다이얼로그 표시 및 삭제 실행
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('이 항목을 삭제하면 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDeleteWorkout();
    }
  }

  /// 삭제 실행 (다이얼로그 없이 실제 삭제만 수행)
  Future<void> _performDeleteWorkout() async {
    if (!mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);

    try {
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _showDeleteConfirmation,
                  tooltip: '운동 삭제',
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
                        scrollPadding: const EdgeInsets.only(bottom: 150.0),
                        onTap: () {
                          final c = _controllers['weight_$setId'];
                          // '0' 또는 '0.0' 모두 처리 (double.toString() 결과 대응)
                          if (c != null && (c.text == '0' || c.text == '0.0')) c.clear();
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
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
                        scrollPadding: const EdgeInsets.only(bottom: 150.0),
                        onTap: () {
                          final c = _controllers['reps_$setId'];
                          if (c != null && c.text == '0') c.clear();
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
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
