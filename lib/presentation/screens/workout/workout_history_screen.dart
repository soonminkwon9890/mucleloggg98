import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../widgets/workout/routine_generation_dialog.dart';
import 'workout_analysis_screen.dart';

/// 지난 운동 기록 화면 (기존 WorkoutLogScreen의 리스트/선택 모드 기능 이관)
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
                    onPressed: _generateRoutineForSelected,
                    tooltip: 'AI 계획 수립',
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
                final uniqueExerciseNames = _getUniqueExerciseNames(baselines);

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
                                value: _selectedBaselineIds.contains(baseline.id),
                                onChanged: (_) => _toggleSelection(baseline.id),
                              )
                            : null,
                        title: Text(exerciseName),
                        trailing:
                            _isSelectionMode ? null : const Icon(Icons.chevron_right),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('오류: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('인증 오류: $error')),
        ),
      ),
    );
  }

  /// 선택된 운동들에 대한 AI 루틴 생성 (기존 WorkoutLogScreen 로직 유지)
  Future<void> _generateRoutineForSelected() async {
    if (_selectedBaselineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('AI가 루틴을 분석 중입니다...')),
          ],
        ),
      ),
    );

    try {
      final repo = ref.read(workoutRepositoryProvider);

      final sessions = await repo.getLastWeekSessions();
      // [DEBUG #1] Total sessions from DB
      debugPrint('====== ROUTINE GENERATION DEBUG ======');
      debugPrint('[DEBUG #1] Total sessions fetched from DB: ${sessions.length}');
      for (final s in sessions) {
        debugPrint('  - Session: baselineId=${s.baselineId}, workoutDate=${s.workoutDate}, difficulty=${s.difficulty}');
      }

      if (sessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('지난주 운동 기록이 없습니다. 운동을 시작해보세요!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final filteredSessions =
          sessions.where((s) => _selectedBaselineIds.contains(s.baselineId)).toList();
      debugPrint('[DEBUG #1.5] Filtered sessions (matching selected baselines): ${filteredSessions.length}');
      debugPrint('  Selected baseline IDs: $_selectedBaselineIds');

      if (filteredSessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('선택한 운동의 지난주 기록이 없습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userGoal = await repo.getUserGoal();

      final baselines = await repo.getBaselinesByIds(_selectedBaselineIds.toList());
      final baselineMap = {for (var b in baselines) b.id: b};

      // [FIX 1] Composite key로 세션별 bestSet 매핑 (baselineId + 날짜)
      // 같은 운동을 여러 날 수행해도 각 세션의 bestSet을 정확히 조회
      // DateFormat('yyyy-MM-dd')로 일관된 날짜 문자열 생성
      final bestSetsFutures = filteredSessions.map((s) async {
        final bestSet = await repo.getLastWeekBestSet(s.baselineId, s.workoutDate);
        final dateStr = DateFormat('yyyy-MM-dd').format(s.workoutDate);
        final compositeKey = '${s.baselineId}_$dateStr';

        debugPrint('[DEBUG #2] Building bestSetsMap entry:');
        debugPrint('  compositeKey=$compositeKey');
        debugPrint('  bestSet: weight=${bestSet.$1}, reps=${bestSet.$2}');
        return MapEntry(compositeKey, bestSet);
      }).toList();
      final bestSetsMap = Map.fromEntries(await Future.wait(bestSetsFutures));

      // [DEBUG] Verify the EXACT keys in bestSetsMap
      debugPrint('[DEBUG #2.5] bestSetsMap FINAL KEYS:');
      for (final key in bestSetsMap.keys) {
        debugPrint('  KEY: "$key"');
      }

     // [수정된 Ghost Session 필터링]
      // getLastWeekBestSet은 기록이 없으면 null을 반환합니다.
      final validSessions = filteredSessions.where((s) {
        final dateStr = DateFormat('yyyy-MM-dd').format(s.workoutDate);
        final compositeKey = '${s.baselineId}_$dateStr';
        
        // 맵에서 데이터를 꺼냈을 때, null이 아니면(실제 기록이 있으면) 통과(true)시킵니다.
        return bestSetsMap[compositeKey] != null;
      }).toList();

      // [DEBUG #3] Valid sessions after bestSet filter
      debugPrint('[DEBUG #3] Valid sessions after bestSet filter: ${validSessions.length}');
      if (validSessions.isEmpty) {
        debugPrint('  ⚠️ ALL SESSIONS FILTERED OUT! This is likely the bug.');
        debugPrint('  BestSetsMap contents:');
        bestSetsMap.forEach((key, value) {
          debugPrint('    $key => (weight=${value.$1}, reps=${value.$2})');
        });
      }

      if (validSessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('완료된 세트가 있는 운동 기록이 없습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // [DEBUG CRITICAL] Verify bestSetsMap keys RIGHT BEFORE calling AI service
      debugPrint('[DEBUG CRITICAL] bestSetsMap keys BEFORE AI call:');
      for (final k in bestSetsMap.keys) {
        debugPrint('  "$k"');
      }

      final plans = await WorkoutRecommendationService.generateWeeklyPlan(
        lastWeekSessions: validSessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: bestSetsMap,
      );

      // [DEBUG #4] Plans generated from AI
      debugPrint('[DEBUG #4] Plans generated from AI: ${plans.length}');
      for (final plan in plans) {
        debugPrint('  - Plan: ${plan.exerciseName}, date=${plan.scheduledDate}, weight=${plan.targetWeight}, reps=${plan.targetReps}');
      }
      debugPrint('====== END ROUTINE GENERATION DEBUG ======');

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
    } catch (e, stackTrace) {
      debugPrint('[DEBUG ERROR] Exception: $e');
      debugPrint('[DEBUG ERROR] StackTrace: $stackTrace');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      final plans = routines.map((dto) {
        return PlannedWorkout(
          id: const Uuid().v4(),
          userId: '',
          baselineId: dto.baselineId,
          scheduledDate: dto.scheduledDate,
          targetWeight: dto.targetWeight,
          targetReps: dto.targetReps,
          targetSets: dto.targetSets,
          aiComment: dto.aiComment,
          isCompleted: false,
          exerciseName: dto.exerciseName,
          isConvertedToLog: false,
          createdAt: DateTime.now(),
          colorHex: colorHex,
        );
      }).toList();
      await repository.savePlannedWorkouts(plans);
      if (mounted) {
        _clearSelection();
        final dateLabel =
            DateFormatter.formatMonthDay(routines.first.scheduledDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dateLabel에 운동이 추가되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
}

