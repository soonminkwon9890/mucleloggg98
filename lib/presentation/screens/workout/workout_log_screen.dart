import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/planned_workout.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../widgets/workout/routine_generation_dialog.dart';
import 'workout_history_screen.dart';

/// 운동 분석 탭 메인 화면 (대시보드)
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  final bool _isPremium = true; // TODO: Premium 연동 전 테스트 플래그
  bool _isGeneratingRoutine = false;

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 분석'),
      ),
      body: SafeArea(
        child: authStateAsync.when(
          data: (isAuthenticated) {
            if (!isAuthenticated) {
              return const Center(
                child: Text('로그인이 필요합니다'),
              );
            }
            return statsAsync.when(
              data: (stats) {
                final weeklyVolume = stats.weeklyVolume;
                final bodyBalance = stats.bodyBalance;

                final aiComment = _buildAiComment(bodyBalance);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardStatsProvider);
                    await ref.read(dashboardStatsProvider.future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PremiumGate(
                          isPremium: _isPremium,
                          child:
                              WeeklyVolumeChartCard(weeklyVolume: weeklyVolume),
                        ),
                        const SizedBox(height: 12),
                        _PremiumGate(
                          isPremium: _isPremium,
                          child: BodyBalanceChartCard(bodyBalance: bodyBalance),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              aiComment,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isGeneratingRoutine
                              ? null
                              : _generateWeeklyRoutine,
                          icon: _isGeneratingRoutine
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: const Text('AI 강도 측정 / 계획 수립'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkoutHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('지난 운동 기록 보러가기'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('오류: $error')),
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

  String _buildAiComment(Map<String, double> bodyBalance) {
    const axes = [
      '가슴',
      '등',
      '어깨',
      '팔',
      '복근',
      '대퇴사두',
      '햄스트링',
      '둔근',
    ];

    final values = axes.map((k) => bodyBalance[k] ?? 0.0).toList();

    // 1) 데이터 없음
    final maxVal = values.fold<double>(0.0, (p, c) => c > p ? c : p);
    if (maxVal <= 0) {
      return '운동 기록이 부족합니다.';
    }

    // 2) 상/하체 그룹 합산
    double sumByKeys(List<String> keys) {
      return keys.fold<double>(0.0, (sum, k) => sum + (bodyBalance[k] ?? 0.0));
    }

    const upperKeys = ['가슴', '등', '어깨', '팔', '복근'];
    const lowerKeys = ['대퇴사두', '햄스트링', '둔근'];

    final upperTotal = sumByKeys(upperKeys);
    final lowerTotal = sumByKeys(lowerKeys);

    const ratioThreshold = 1.5;

    // 3) Case A/B: 그룹 불균형이 큰 경우
    if (lowerTotal >= upperTotal * ratioThreshold) {
      return '하체 비중이 높습니다. 전반적인 상체 운동을 보강해 보세요.';
    }
    if (upperTotal >= lowerTotal * ratioThreshold) {
      return '상체 비중이 높습니다. 하체 운동 밸런스를 맞춰보세요.';
    }

    // 4) Case C: 균형/기타 → 가장 낮은 단일 부위 언급
    final minVal =
        values.fold<double>(double.infinity, (p, c) => c < p ? c : p);
    final minIdx = values.indexOf(minVal);
    final minAxis = axes[minIdx];
    return '$minAxis 운동이 가장 부족해요.';
  }

  Future<void> _generateWeeklyRoutine() async {
    if (_isGeneratingRoutine) return;
    setState(() => _isGeneratingRoutine = true);

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

      final userGoal = await repo.getUserGoal();
      final baselineIds = sessions.map((s) => s.baselineId).toSet().toList();
      final baselines = await repo.getBaselinesByIds(baselineIds);
      final baselineMap = {for (var b in baselines) b.id: b};

      final bestSetsFutures = sessions.map((s) async {
        final bestSet = await repo.getLastWeekBestSet(s.baselineId, s.workoutDate);
        return MapEntry(s.baselineId, bestSet);
      }).toList();
      final bestSetsMap = Map.fromEntries(await Future.wait(bestSetsFutures));

      final plans = await WorkoutRecommendationService.generateWeeklyPlan(
        lastWeekSessions: sessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: bestSetsMap,
      );

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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingRoutine = false);
    }
  }

  /// 루틴 생성 다이얼로그 표시 (결과: 날짜가 주입된 루틴 + 색상)
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
      final plans = routines
          .map(
            (dto) => dto.toPlannedWorkout(
              colorHex: colorHex,
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      await repository.savePlannedWorkouts(plans);
      if (mounted) {
        final dateLabel = DateFormat('M월 d일', 'ko_KR').format(routines.first.scheduledDate);
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

extension on PlannedWorkoutDto {
  PlannedWorkout toPlannedWorkout({
    required String colorHex,
    required DateTime createdAt,
  }) {
    return PlannedWorkout(
      id: const Uuid().v4(),
      userId: '',
      baselineId: baselineId,
      scheduledDate: scheduledDate,
      targetWeight: targetWeight,
      targetReps: targetReps,
      targetSets: targetSets,
      aiComment: aiComment,
      isCompleted: false,
      exerciseName: exerciseName,
      isConvertedToLog: false,
      createdAt: createdAt,
      colorHex: colorHex,
    );
  }
}

class WeeklyVolumeChartCard extends StatelessWidget {
  final Map<DateTime, double> weeklyVolume;

  const WeeklyVolumeChartCard({
    super.key,
    required this.weeklyVolume,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i)),
    );

    final values = days.map((d) => weeklyVolume[d] ?? 0.0).toList();
    final maxY = values.fold<double>(0.0, (p, c) => c > p ? c : p);

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < days.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context).colorScheme.primary,
              width: 14,
            ),
          ],
        ),
      );
    }

    String weekdayKo(DateTime d) {
      switch (d.weekday) {
        case DateTime.monday:
          return '월';
        case DateTime.tuesday:
          return '화';
        case DateTime.wednesday:
          return '수';
        case DateTime.thursday:
          return '목';
        case DateTime.friday:
          return '금';
        case DateTime.saturday:
          return '토';
        case DateTime.sunday:
          return '일';
      }
      return '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주간 총 운동 볼륨',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 0 ? 10 : maxY * 1.2,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              weekdayKo(days[idx]),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = days[group.x.toInt()];
                        final label = DateFormat('M/d (E)', 'ko_KR').format(d);
                        final v = rod.toY;
                        return BarTooltipItem(
                          '$label\n${v.toStringAsFixed(0)} kg',
                          const TextStyle(color: Colors.white),
                        );
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
}

class BodyBalanceChartCard extends StatelessWidget {
  final Map<String, double> bodyBalance;

  const BodyBalanceChartCard({
    super.key,
    required this.bodyBalance,
  });

  static const _axes = [
    '가슴',
    '등',
    '어깨',
    '팔',
    '복근',
    '대퇴사두',
    '햄스트링',
    '둔근',
  ];

  @override
  Widget build(BuildContext context) {
    final values = _axes.map((k) => bodyBalance[k] ?? 0.0).toList();
    final maxVal = values.fold<double>(0.0, (p, c) => c > p ? c : p);
    // fl_chart 0.66.x RadarChartData는 max 값을 직접 받지 않습니다.
    // 요구사항(꽉 차 보이기)을 만족하기 위해 값을 0~10 범위로 정규화합니다.
    final scaleBase = maxVal <= 0 ? 10.0 : maxVal;
    final scaledEntries = values
        .map((v) => maxVal <= 0 ? 0.0 : (v / scaleBase) * 10.0)
        .map((v) => RadarEntry(value: v))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '부위별 밸런스',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarBackgroundColor: Colors.transparent,
                  radarShape: RadarShape.polygon,
                  radarBorderData: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                  tickBorderData: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                  gridBorderData: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                  titleTextStyle: const TextStyle(fontSize: 11),
                  titlePositionPercentageOffset: 0.15,
                  tickCount: 4,
                  getTitle: (index, angle) {
                    return RadarChartTitle(
                      text: _axes[index],
                    );
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      borderColor: Theme.of(context).colorScheme.primary,
                      entryRadius: 2,
                      borderWidth: 2,
                      dataEntries: scaledEntries,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumGate extends StatelessWidget {
  final bool isPremium;
  final Widget child;

  const _PremiumGate({
    required this.isPremium,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black12,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Premium 결제 시 확인 가능',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
