import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../viewmodels/home_state.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../widgets/workout/workout_card.dart';
import '../../widgets/workout/exercise_add_panel.dart';

/// 홈 화면 (Single Page UX - 당일 운동 기록)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ViewModel 초기화 또는 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).loadBaselines();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // [안전핀] 앱이 포그라운드로 돌아올 때 날짜 변경 체크
    if (state == AppLifecycleState.resumed) {
      ref.read(homeViewModelProvider.notifier).checkDateAndRefresh();
    }
  }

  /// 루틴 저장 다이얼로그
  Future<void> _showSaveRoutineDialog(
      List<ExerciseBaseline> todayWorkouts) async {
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

    await ref
        .read(homeViewModelProvider.notifier)
        .saveRoutine(result, todayWorkouts);

    if (mounted && context.mounted) {
      final errorMessage =
          ref.read(homeViewModelProvider).errorMessage;
      if (errorMessage != null && errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $errorMessage')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 저장되었습니다.')),
        );
        // Provider 갱신
        ref.invalidate(archivedBaselinesProvider);
        ref.invalidate(routinesProvider);
        ref.invalidate(workoutDatesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 1. 창 열기 (우측 슬라이드 패널)
          final bool? result = await showGeneralDialog<bool>(
            context: context,
            barrierDismissible: true,
            barrierLabel: "Dismiss",
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) {
              final panelWidth = math.max(
                MediaQuery.of(context).size.width * 0.5,
                300.0,
              );
              return Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: panelWidth,
                  height: double.infinity,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // 오른쪽 방향(delta > 0) 스와이프 시 닫기
                      if (details.delta.dx > 0) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: const SafeArea(
                        child: ExerciseAddPanel(),
                      ),
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
          );

          // 2. 창이 닫힌 후 결과가 true면 갱신 (여기서 갱신해야 안전함)
          if (result == true && context.mounted) {
            ref.read(homeViewModelProvider.notifier).loadBaselines();
          }
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

            return _buildContent(homeState);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('인증 오류: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(HomeState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(child: Text('오류: ${state.errorMessage}'));
    }

    final groupedWorkouts = state.groupedWorkouts;
    final allTodayWorkouts =
        groupedWorkouts.values.expand((list) => list).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeViewModelProvider.notifier).refresh();
        ref.invalidate(workoutDatesProvider);
        await ref.read(workoutDatesProvider.future);
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
                      '${state.totalVolume.toStringAsFixed(1)}kg',
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
                      state.mainFocusArea,
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      final routineNameMap = {
                        for (var r in routines) r.id: r.name
                      };

                      // Fallback: 루틴이 삭제/로드 실패 등으로 이름 매핑이 없는 그룹은 'new'로 병합
                      final mergedNewWorkouts = <ExerciseBaseline>[
                        ...?groupedWorkouts['new'],
                        for (final entry in groupedWorkouts.entries)
                          if (entry.key != 'new' &&
                              routineNameMap[entry.key] == null)
                            ...entry.value,
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 신규 운동 섹션
                          if (mergedNewWorkouts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
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
                            ...mergedNewWorkouts.map((baseline) {
                              return WorkoutCard(
                                key: ValueKey(baseline.id),
                                baseline: baseline,
                                onUpdated: () {
                                  ref
                                      .read(homeViewModelProvider.notifier)
                                      .loadBaselines();
                                },
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          // 루틴별 섹션
                          ...groupedWorkouts.entries
                              .where((entry) =>
                                  entry.key != 'new' &&
                                  routineNameMap[entry.key] != null)
                              .map((entry) {
                            final routineId = entry.key;
                            final routineName = routineNameMap[routineId]!;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                key: PageStorageKey('routine_$routineId'),
                                maintainState: true,
                                initiallyExpanded: true,
                                title: Row(
                                  children: [
                                    Icon(Icons.fitness_center,
                                        color: Colors.green.shade700),
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
                                      ref
                                          .read(homeViewModelProvider.notifier)
                                          .loadBaselines();
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Text('루틴 정보 로딩 오류: $error'),
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
                    onPressed: () => _showSaveRoutineDialog(allTodayWorkouts),
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('오늘 운동을 루틴으로 저장'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
