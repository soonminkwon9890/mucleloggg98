import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../providers/workout_provider.dart';
import '../../screens/workout/workout_analysis_screen.dart';

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
  Timer? _debounceTimer;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, WorkoutSet> _sets = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSets();
  }

  void _initializeSets() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (widget.baseline.workoutSets != null) {
      for (final set in widget.baseline.workoutSets!) {
        if (set.createdAt == null) continue;
        final setDate =
            '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}-${set.createdAt!.day.toString().padLeft(2, '0')}';
        if (setDate == todayStr) {
          _sets[set.id] = set;
          _controllers['weight_${set.id}'] =
              TextEditingController(text: set.weight.toString());
          _controllers['reps_${set.id}'] =
              TextEditingController(text: set.reps.toString());
          // sets 컨트롤러 제거 (인덱스 기반 표시)
        }
      }
    }

    // 오늘 세트가 없으면 초기 세트 하나 생성
    if (_sets.isEmpty) {
      final newSet = WorkoutSet(
        id: const Uuid().v4(),
        baselineId: widget.baseline.id,
        weight: 0.0,
        reps: 0,
        sets: 1, // 초기 세트 번호
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      _sets[newSet.id] = newSet;
      _controllers['weight_${newSet.id}'] = TextEditingController(text: '0');
      _controllers['reps_${newSet.id}'] = TextEditingController(text: '0');
      _controllers['sets_${newSet.id}'] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
      // sets 컨트롤러 제거 (더 이상 필요 없음)
    });
  }

  Future<void> _saveWorkoutCard() async {
    if (!mounted) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);

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
        final completedSet = set.copyWith(
          weight: weight,
          reps: reps,
          sets: setsCount, // 인덱스 기반 세트 번호 (1부터 시작)
          isCompleted: true, // [중요] Smart Delete 보호 & 보관함 표시를 위해 반드시 true
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
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오늘 기록 삭제'),
        content: const Text('이 운동의 오늘 기록을 모두 삭제하시겠습니까?'),
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
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(workoutRepositoryProvider)
          .deleteTodayWorkoutsByBaseline(widget.baseline.id);

      // Provider 갱신 (홈 화면과 보관함 동시 갱신)
      ref.invalidate(baselinesProvider);
      ref.invalidate(archivedBaselinesProvider);

      messenger.showSnackBar(const SnackBar(content: Text('오늘 기록이 삭제되었습니다.')));

      // 콜백 호출 (홈 화면에서 카드 제거)
      widget.onUpdated();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('기록 삭제 오류: $e')));
    }
  }

  void _onFieldChanged(String setId, String field, String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _saveSet(setId, field, value);
    });
  }

  Future<void> _saveSet(String setId, String field, String value) async {
    final set = _sets[setId];
    if (set == null) return;

    try {
      final numValue = double.tryParse(value) ?? 0.0;
      final updatedSet = set.copyWith(
        weight: field == 'weight' ? numValue : set.weight,
        reps: field == 'reps' ? numValue.toInt() : set.reps,
        // sets 필드는 더 이상 사용자 입력을 받지 않음 (인덱스 기반으로 표시)
      );

      final repository = ref.read(workoutRepositoryProvider);
      await repository.upsertWorkoutSet(updatedSet);

      setState(() {
        _sets[setId] = updatedSet;
      });

      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 오류: $e')),
        );
      }
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
                          baseline: widget.baseline,
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
                        decoration: const InputDecoration(
                          labelText: '무게 (kg)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _onFieldChanged(setId, 'weight', value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controllers['reps_$setId'],
                        decoration: const InputDecoration(
                          labelText: '횟수',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _onFieldChanged(setId, 'reps', value),
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
