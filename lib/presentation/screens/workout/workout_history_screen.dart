import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/planner_consent_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import 'workout_analysis_screen.dart';
import '../planner/weekly_routine_planner_screen.dart';

/// 지난 운동 기록 화면
///
/// 선택 모드에서 운동을 고른 뒤 AI 플래너 버튼을 누르면
/// [PlannerConsentHelper] 동의 확인 후 [WeeklyRoutinePlannerScreen] 으로 이동합니다.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedBaselineIds = {};

  void _toggleSelection(String baselineId) {
    setState(() {
      if (_selectedBaselineIds.contains(baselineId)) {
        _selectedBaselineIds.remove(baselineId);
      } else {
        _selectedBaselineIds.add(baselineId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedBaselineIds.clear();
    });
  }

  List<String> _getUniqueExerciseNames(List<ExerciseBaseline> baselines) {
    final uniqueNames = <String>{};
    for (final baseline in baselines) {
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        continue;
      }
      final hasCompletedSets =
          baseline.workoutSets!.any((set) => set.isCompleted);
      if (hasCompletedSets) {
        uniqueNames.add(baseline.exerciseName);
      }
    }
    return uniqueNames.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(archivedBaselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedBaselineIds.length}개 선택됨')
            : const Text('지난 운동 기록'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: _isSelectionMode
            ? [
                if (_selectedBaselineIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: _handleAiCoachingRequest,
                    tooltip: 'AI 주간 플래너',
                  ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                  tooltip: '선택 모드',
                ),
              ],
      ),
      body: SafeArea(
        child: authStateAsync.when(
          data: (isAuthenticated) {
            if (!isAuthenticated) {
              return const Center(child: Text('로그인이 필요합니다'));
            }

            return baselinesAsync.when(
              data: (baselines) {
                final uniqueExerciseNames =
                    _getUniqueExerciseNames(baselines);

                if (uniqueExerciseNames.isEmpty) {
                  return const Center(child: Text('기록된 운동이 없습니다'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(archivedBaselinesProvider);
                    await ref.read(archivedBaselinesProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: uniqueExerciseNames.length,
                    itemBuilder: (context, index) {
                      final exerciseName = uniqueExerciseNames[index];
                      final baseline = baselines.firstWhere(
                        (b) => b.exerciseName == exerciseName,
                        orElse: () => baselines.first,
                      );

                      return ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: _selectedBaselineIds
                                    .contains(baseline.id),
                                onChanged: (_) =>
                                    _toggleSelection(baseline.id),
                              )
                            : null,
                        title: Text(exerciseName),
                        trailing: _isSelectionMode
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(baseline.id)
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkoutAnalysisScreen(
                                      exerciseName: exerciseName,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('오류: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('인증 오류: $error')),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI 주간 플래너 진입점
  // ---------------------------------------------------------------------------

  /// PIPA 동의를 확인한 뒤 [WeeklyRoutinePlannerScreen] 으로 이동합니다.
  ///
  /// 동의가 이미 완료된 경우 다이얼로그 없이 즉시 이동합니다.
  /// 동의를 거부하거나 context 가 unmount 되면 아무 작업도 하지 않습니다.
  Future<void> _handleAiCoachingRequest() async {
    if (_selectedBaselineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final consented = await PlannerConsentHelper.ensureConsent(context);
    if (!consented || !mounted) return;

    // 플래너 화면으로 이동 — 선택된 baseline ID 세트를 전달
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyRoutinePlannerScreen(
          selectedBaselineIds: Set.from(_selectedBaselineIds),
        ),
      ),
    );

    // 플래너에서 돌아오면 선택 모드 해제
    _clearSelection();
  }
}
