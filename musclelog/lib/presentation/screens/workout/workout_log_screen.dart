import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../workout/workout_analysis_screen.dart';

/// 운동 기록 화면 (날짜별 그룹화)
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  // 날짜별로 그룹화된 운동 기록
  Map<String, List<ExerciseBaseline>> _groupedByDate = {};
  final Set<String> _expandedBaselineIds = {};

  Map<String, List<ExerciseBaseline>> _groupWorkoutsByDate(
      List<ExerciseBaseline> baselines) {
    final Map<String, List<ExerciseBaseline>> grouped = {};

    for (final baseline in baselines) {
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        continue;
      }

      // [수정] 완료된 세트만 필터링 (Data Integrity)
      final completedSets = baseline.workoutSets!
          .where((set) => set.isCompleted)
          .toList();
      
      if (completedSets.isEmpty) continue; // 완료된 세트가 없으면 목록에서 제외

      // 각 세트의 날짜를 기준으로 그룹화
      for (final set in completedSets) {
        if (set.createdAt == null) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(set.createdAt!);

        grouped.putIfAbsent(dateKey, () => []);

        // 같은 날짜에 같은 baseline이 중복 추가되지 않도록 방지
        if (!grouped[dateKey]!.any((b) => b.id == baseline.id)) {
          grouped[dateKey]!.add(baseline);
        }
      }
    }

    // 날짜 내림차순 정렬 (최신순)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedMap = <String, List<ExerciseBaseline>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(archivedBaselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      // [AppBar 제거] MainScreen의 AppBar를 사용
      body: SafeArea(
        child: authStateAsync.when(
          data: (isAuthenticated) {
            if (!isAuthenticated) {
              return const Center(
                child: Text('로그인이 필요합니다'),
              );
            }

            return baselinesAsync.when(
              data: (baselines) {
                _groupedByDate = _groupWorkoutsByDate(baselines);

                if (_groupedByDate.isEmpty) {
                  return const Center(
                    child: Text('기록된 운동이 없습니다'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(archivedBaselinesProvider);
                    await ref.read(archivedBaselinesProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groupedByDate.length,
                    itemBuilder: (context, index) {
                      final dateKey = _groupedByDate.keys.elementAt(index);
                      final workouts = _groupedByDate[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜 헤더
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 해당 날짜의 운동 리스트
                          ...workouts.map((baseline) {
                            final isExpanded =
                                _expandedBaselineIds.contains(baseline.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(baseline.exerciseName),
                                    trailing: Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedBaselineIds
                                              .remove(baseline.id);
                                        } else {
                                          _expandedBaselineIds.add(baseline.id);
                                        }
                                      });
                                    },
                                  ),
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkoutAnalysisScreen(
                                                    baseline: baseline,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.analytics),
                                            label: const Text('운동 분석'),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              _showIntensityDialog(baseline);
                                            },
                                            icon: const Icon(Icons.trending_up),
                                            label: const Text('강도 설정'),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류: $error'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('인증 오류: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _showIntensityDialog(ExerciseBaseline baseline) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final sets = await repository.getWorkoutSets(baseline.id);

      if (sets.length < 3) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('강도 설정'),
              content: const Text(
                '더 정확한 분석을 위해 3회 이상 운동 기록이 필요합니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 최근 3회 이상 기록의 Volume 가중 평균 계산
      final recentSets = sets.take(3).toList();
      double totalWeightedVolume = 0.0;
      double totalWeight = 0.0;

      for (var i = 0; i < recentSets.length; i++) {
        final weight = (recentSets.length - i).toDouble(); // 최신일수록 높은 가중치
        final volume = recentSets[i].weight * recentSets[i].reps;
        totalWeightedVolume += volume * weight;
        totalWeight += weight;
      }

      final avgVolume = totalWeightedVolume / totalWeight;
      final latestSet = recentSets.first;
      final avgWeight = latestSet.weight;
      final avgReps = latestSet.reps;

      // 다음 목표 추천 (볼륨 기반)
      final recommendedWeight = avgWeight * 1.05; // 5% 증가
      final recommendedReps = avgReps;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('강도 추천'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최근 평균 볼륨: ${avgVolume.toStringAsFixed(1)}kg'),
                const SizedBox(height: 16),
                const Text(
                  '다음 목표:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                    '${recommendedWeight.toStringAsFixed(1)}kg × $recommendedReps회'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
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
}
