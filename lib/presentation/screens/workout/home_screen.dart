import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../viewmodels/home_state.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../widgets/workout/workout_card.dart';
import '../../widgets/workout/exercise_add_panel.dart';
import '../management/management_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/premium_guidance_dialog.dart';

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
    // ViewModel 초기화 또는 데이터 로드 (Draft 보존을 위해 forceRefresh=false)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).loadBaselines(forceRefresh: false);
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

    // Check routine limit: 3 free, then premium required
    final routines = await ref.read(routinesProvider.future);
    final isPremium = ref.read(subscriptionProvider).isPremium;

    if (!isPremium && routines.length >= 3) {
      if (!mounted) return;
      final isPurchased = await showPremiumGuidanceDialog(context);
      if (isPurchased == true && context.mounted) {
        ref.invalidate(subscriptionProvider);
        // 결제 성공 후 루틴 저장 재시도
        ref.invalidate(routinesProvider);
      }
      return;
    }

    if (!mounted) return;

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
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 1. 창 열기 (우측 슬라이드 패널)
          await showGeneralDialog<bool>(
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

          // 2. 창이 닫힌 후: addNewExercise는 메모리 전용이므로 loadBaselines() 호출 불필요
          // Draft는 이미 state에 추가되었으므로 새로고침하지 않음
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeViewModelProvider.notifier).refresh();
          ref.invalidate(workoutDatesProvider);
          await ref.read(workoutDatesProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 150.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 상단 요약 카드
            Builder(
              builder: (context) {
                final appCard = Theme.of(context).extension<AppCardTheme>();
                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '오늘 총 볼륨',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: appCard?.subTextColor ?? Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManagementScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.inventory_2_outlined, size: 18),
                              label: const Text('보관함'),
                              style: TextButton.styleFrom(
                                foregroundColor: appCard?.subTextColor ?? Colors.grey,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.totalVolume.toStringAsFixed(1)}kg',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: appCard?.onCardColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(
                          color: appCard?.subTextColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '오늘의 집중',
                          style: TextStyle(
                            fontSize: 16,
                            color: appCard?.subTextColor ?? Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.mainFocusArea,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: appCard?.onCardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 오늘의 운동 섹션 헤더 (루틴 저장 버튼 포함)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '오늘의 운동',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (allTodayWorkouts.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showSaveRoutineDialog(allTodayWorkouts),
                    icon: const Icon(Icons.bookmark_add, size: 18),
                    label: const Text('루틴 저장'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
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
                                onUpdated: (savedItem, oldId) {
                                  if (savedItem != null && oldId != null) {
                                    ref
                                        .read(homeViewModelProvider.notifier)
                                        .replaceBaselineAfterSave(
                                            oldId, savedItem);
                                  } else {
                                    ref
                                        .read(homeViewModelProvider.notifier)
                                        .loadBaselines(forceRefresh: true);
                                  }
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

                            return Builder(
                              builder: (context) {
                                final appCard = Theme.of(context).extension<AppCardTheme>();
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ExpansionTile(
                                    key: PageStorageKey('routine_$routineId'),
                                    maintainState: true,
                                    initiallyExpanded: true,
                                    iconColor: appCard?.onCardColor,
                                    collapsedIconColor: appCard?.onCardColor,
                                    title: Row(
                                      children: [
                                        Icon(Icons.fitness_center,
                                            color: appCard?.onCardColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          routineName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: appCard?.onCardColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: entry.value.map((baseline) {
                                      return WorkoutCard(
                                        key: ValueKey(baseline.id),
                                        baseline: baseline,
                                        onUpdated: (savedItem, oldId) {
                                          if (savedItem != null && oldId != null) {
                                            ref
                                                .read(homeViewModelProvider
                                                    .notifier)
                                                .replaceBaselineAfterSave(
                                                    oldId, savedItem);
                                          } else {
                                            ref
                                                .read(homeViewModelProvider
                                                    .notifier)
                                                .loadBaselines(forceRefresh: true);
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
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
          ],
        ),
      ),
    ),
    );
  }
}
