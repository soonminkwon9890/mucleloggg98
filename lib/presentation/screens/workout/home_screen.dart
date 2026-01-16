import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../core/enums/exercise_enums.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/workout/workout_card.dart';
import '../../widgets/workout/exercise_add_panel.dart';

/// 홈 화면 (Single Page UX - 당일 운동 기록)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, List<ExerciseBaseline>> _getTodayWorkouts(List<ExerciseBaseline> baselines) {
    // Repository에서 이미 is_hidden_from_home == false 조건으로 필터링했으므로,
    // Baseline 날짜 필터 없이 모든 항목을 표시
    final filtered = baselines.toList();

    // 중복 제거: 같은 baseline_id를 가진 운동은 한 번만 표시
    final seenIds = <String>{};
    final uniqueFiltered = filtered.where((baseline) {
      if (seenIds.contains(baseline.id)) {
        return false;
      }
      seenIds.add(baseline.id);
      return true;
    }).toList();

    // [핵심 수정] 정렬 로직 추가
    // 1순위: 신규 운동 (routineId == null, createdAt 오름차순 = FIFO)
    // 2순위: 루틴 운동 (routineId != null, createdAt 오름차순)
    uniqueFiltered.sort((a, b) {
      // routineId가 null인 것을 먼저 (신규 운동)
      if (a.routineId == null && b.routineId != null) return -1;
      if (a.routineId != null && b.routineId == null) return 1;
      
      // 같은 그룹 내에서는 createdAt 오름차순 (오래된 것이 먼저 = FIFO)
      // [방어 로직] createdAt이 null인 경우 DateTime(1970) 사용
      final aTime = a.createdAt ?? DateTime(1970);
      final bTime = b.createdAt ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });

    // routine_id 기준으로 그룹화 (정렬된 순서 유지)
    final Map<String, List<ExerciseBaseline>> grouped = {};
    for (final baseline in uniqueFiltered) {
      final key = baseline.routineId ?? "new";
      grouped.putIfAbsent(key, () => []).add(baseline);
    }
    
    return grouped;
  }

  /// 오늘의 총 볼륨 계산 (weight * reps 합계)
  double _calculateTodayVolume(List<ExerciseBaseline> todayWorkouts) {
    double totalVolume = 0.0;
    final now = DateTime.now();

    for (final baseline in todayWorkouts) {
      if (baseline.workoutSets == null) continue;
      for (final set in baseline.workoutSets!) {
        if (DateFormatter.isSameDate(set.createdAt, now)) {
          totalVolume += set.weight * set.reps;
        }
      }
    }
    return totalVolume;
  }

  /// 오늘 기록 중 볼륨이 가장 높은 부위와 타입 찾기
  String _getMainFocusArea(List<ExerciseBaseline> todayWorkouts) {
    final now = DateTime.now();

    // 부위별 볼륨 집계
    final Map<String, double> volumeByCategory = {};

    for (final baseline in todayWorkouts) {
      if (baseline.workoutSets == null) continue;

      final bodyPartKr = baseline.bodyPart?.label ?? '';
      final movementTypeKr = baseline.movementType?.label ?? '';

      for (final set in baseline.workoutSets!) {
        if (DateFormatter.isSameDate(set.createdAt, now)) {
          final categoryKey = bodyPartKr.isNotEmpty
              ? (movementTypeKr.isNotEmpty
                  ? '$bodyPartKr($movementTypeKr)'
                  : bodyPartKr)
              : '기타';
          volumeByCategory[categoryKey] =
              (volumeByCategory[categoryKey] ?? 0.0) + (set.weight * set.reps);
        }
      }
    }

    if (volumeByCategory.isEmpty) {
      return '기록 없음';
    }

    // 가장 높은 볼륨을 가진 카테고리 찾기
    final maxEntry = volumeByCategory.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return maxEntry.key;
  }

  /// 루틴 저장
  Future<void> _saveRoutine(List<ExerciseBaseline> todayWorkouts) async {
    if (todayWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 운동이 없습니다.')),
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
      
      // [수정] saveRoutineFromWorkouts 호출
      await repository.saveRoutineFromWorkouts(result, todayWorkouts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 저장되었습니다.')),
        );
        
        // Provider 갱신
        ref.invalidate(baselinesProvider);
        ref.invalidate(archivedBaselinesProvider);
        ref.invalidate(routinesProvider);
        ref.invalidate(workoutDatesProvider);
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
    final baselinesAsync = ref.watch(baselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      // [AppBar 제거] MainScreen의 AppBar를 사용
      endDrawer: ExerciseAddPanel(
        onExerciseAdded: () {
          Navigator.pop(context);
          ref.invalidate(baselinesProvider);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        icon: const Icon(Icons.add),
        label: const Text('신규 운동 추가'),
      ),
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
                final groupedWorkouts = _getTodayWorkouts(baselines);
                // 모든 운동을 평탄화하여 볼륨 계산
                final allTodayWorkouts = groupedWorkouts.values.expand((list) => list).toList();
                final totalVolume = _calculateTodayVolume(allTodayWorkouts);
                final mainFocus = _getMainFocusArea(allTodayWorkouts);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(baselinesProvider);
                    ref.invalidate(workoutDatesProvider);
                    await Future.wait([
                      ref.read(baselinesProvider.future),
                      ref.read(workoutDatesProvider.future),
                    ]);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 요약 카드
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '오늘 총 볼륨',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${totalVolume.toStringAsFixed(1)}kg',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  '오늘의 집중',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mainFocus,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 오늘의 운동 섹션
                        const Text(
                          '오늘의 운동',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (groupedWorkouts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('오늘 기록된 운동이 없습니다'),
                            ),
                          )
                        else
                          Consumer(
                            builder: (context, ref, child) {
                              final routinesAsync = ref.watch(routinesProvider);
                              return routinesAsync.when(
                                data: (routines) {
                                  // 루틴 이름 매핑
                                  final routineNameMap = {for (var r in routines) r.id: r.name};
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 신규 운동 섹션
                                      if (groupedWorkouts.containsKey("new")) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              '신규 운동',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...groupedWorkouts["new"]!.map((baseline) {
                                          return WorkoutCard(
                                            key: ValueKey(baseline.id),
                                            baseline: baseline,
                                            onUpdated: () {
                                              ref.invalidate(baselinesProvider);
                                            },
                                          );
                                        }),
                                        const SizedBox(height: 16),
                                      ],
                                      // 루틴별 섹션
                                      ...groupedWorkouts.entries.where((entry) => entry.key != "new").map((entry) {
                                        final routineId = entry.key;
                                        final routineName = routineNameMap[routineId] ?? "알 수 없는 루틴";
                                        
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          child: ExpansionTile(
                                            key: PageStorageKey('routine_$routineId'),
                                            initiallyExpanded: true, // 기본적으로 펼쳐짐
                                            title: Row(
                                              children: [
                                                Icon(Icons.fitness_center, color: Colors.green.shade700),
                                                const SizedBox(width: 8),
                                                Text(
                                                  routineName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: entry.value.map((baseline) {
                                              return WorkoutCard(
                                                key: ValueKey(baseline.id),
                                                baseline: baseline,
                                                onUpdated: () {
                                                  ref.invalidate(baselinesProvider);
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, stack) => Text('루틴 정보 로딩 오류: $error'),
                              );
                            },
                          ),
                        const SizedBox(height: 16),

                        // 루틴화 버튼
                        if (allTodayWorkouts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _saveRoutine(allTodayWorkouts),
                                icon: const Icon(Icons.bookmark_add),
                                label: const Text('오늘 운동을 루틴으로 저장'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
}
