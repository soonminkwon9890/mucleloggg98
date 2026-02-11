import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/planned_workout.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../widgets/workout/routine_generation_dialog.dart';
import '../subscription/subscription_screen.dart';
import 'workout_history_screen.dart';

/// 운동 분석 탭 메인 화면 (대시보드)
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  bool _isGeneratingRoutine = false;
  late DateTime _selectedWeekStart;

  /// Provider 캐시 일관성을 위해 주 시작일을 날짜(00:00:00)만 남겨 반환
  static DateTime _normalizeWeekStart(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  @override
  void initState() {
    super.initState();
    // 초기값: 이번 주 월요일 (날짜만 사용해 캐시/중복 호출 방지)
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    _selectedWeekStart = _normalizeWeekStart(
        todayLocal.subtract(Duration(days: now.weekday - 1)));
  }

  /// 시분초를 무시하고 날짜 단위로만 비교하여 현재 주인지 확인
  bool _isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final currentWeekStart = todayLocal.subtract(Duration(days: now.weekday - 1));

    // 날짜 단위로만 비교 (시분초 무시)
    final dateNormalized = DateTime(date.year, date.month, date.day);
    final currentWeekStartNormalized = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );

    return dateNormalized.year == currentWeekStartNormalized.year &&
        dateNormalized.month == currentWeekStartNormalized.month &&
        dateNormalized.day == currentWeekStartNormalized.day;
  }

  /// 주 표시 포맷팅을 위한 유틸리티 함수
  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormatted = DateFormat('yyyy년 M월 d일', 'ko_KR').format(weekStart);
    final endFormatted = DateFormat('M월 d일', 'ko_KR').format(weekEnd);
    return '$startFormatted ~ $endFormatted';
  }

  /// 미래 주차 이동 제한 로직
  bool _canMoveToNextWeek() {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final currentWeekStart = todayLocal.subtract(Duration(days: now.weekday - 1));

    // _selectedWeekStart가 현재 주 이전인지 확인
    return _selectedWeekStart.isBefore(currentWeekStart);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedWeekStart = _normalizeWeekStart(_selectedWeekStart);
    final authStateAsync = ref.watch(authStateProvider);
    final statsAsync = ref.watch(dashboardStatsProvider(normalizedWeekStart));
    final isPremium = ref.watch(subscriptionProvider).isPremium;
    final isCurrentWeek = _isCurrentWeek(_selectedWeekStart);

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
                // 날짜 변경 시 bodyBalance가 바뀌는지 검증용 (필요 시 주석 해제)
                // debugPrint('BodyBalance Hash: ${bodyBalance.hashCode}');

                final aiComment = _buildAiComment(bodyBalance);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        dashboardStatsProvider(normalizedWeekStart));
                    await ref
                        .read(dashboardStatsProvider(normalizedWeekStart).future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 주 선택기 UI
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setState(() {
                                    final next = _selectedWeekStart
                                        .subtract(const Duration(days: 7));
                                    _selectedWeekStart =
                                        _normalizeWeekStart(next);
                                  });
                                },
                              ),
                              Text(
                                _formatWeekRange(_selectedWeekStart),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: _canMoveToNextWeek()
                                      ? Theme.of(context).iconTheme.color
                                      : Theme.of(context).disabledColor,
                                ),
                                onPressed: _canMoveToNextWeek()
                                    ? () {
                                        setState(() {
                                          final next = _selectedWeekStart
                                              .add(const Duration(days: 7));
                                          _selectedWeekStart =
                                              _normalizeWeekStart(next);
                                        });
                                      }
                                    : null, // 미래 주는 비활성화
                              ),
                            ],
                          ),
                        ),
                        _PremiumGate(
                          isPremium: isPremium,
                          isCurrentWeek: isCurrentWeek,
                          icon: Icons.show_chart, // 추가
                          message: '지난 성장 그래프를 확인하고 정체기를 돌파하세요!', // 추가
                          child:
                              WeeklyVolumeChartCard(weeklyVolume: weeklyVolume),
                        ),
                        const SizedBox(height: 12),
                        _PremiumGate(
                          isPremium: isPremium,
                          isCurrentWeek: isCurrentWeek,
                          icon: Icons.pie_chart, // 추가
                          message: '신체 불균형을 분석하여 완벽한 밸런스를 찾으세요.', // 추가
                          child: BodyBalanceChartCard(
                            key: ValueKey(
                                'balance_${normalizedWeekStart.toIso8601String()}'),
                            bodyBalance: bodyBalance,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAiCommentCard(
                          context,
                          aiComment: aiComment,
                          isPremium: isPremium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isGeneratingRoutine
                              ? null
                              : (isPremium
                                  ? _generateWeeklyRoutine
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text('프리미엄이 필요합니다'),
                                          action: SnackBarAction(
                                            label: '멤버십 보기',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SubscriptionScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
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
                                builder: (_) =>
                                    const WorkoutHistoryScreen(),
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
              error: (error, stackTrace) {
                // 에러 UI: 재시도 버튼 포함
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '데이터를 불러오는 중 오류가 발생했습니다.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            // 재시도: provider를 invalidate하여 다시 로드
                            ref.invalidate(
                                dashboardStatsProvider(normalizedWeekStart));
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('재시도'),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  /// AI 코멘트 카드. 무료 유저는 Blur + 더미 텍스트(빈 경우) + AbsorbPointer 적용.
  static const _aiBlurDummyText =
      '회원님의 운동 데이터를 기반으로 AI가 정밀 분석 중입니다. '
      'Pro 버전에서 상세한 강도 분석과 맞춤 코멘트를 확인하실 수 있습니다.';

  Widget _buildAiCommentCard(
    BuildContext context, {
    required String aiComment,
    required bool isPremium,
  }) {
    if (isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            aiComment,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      );
    }

    // 무료: 블러가 잘 보이도록 비어 있으면 긴 더미 텍스트 사용
    final displayText = aiComment.trim().isEmpty ? _aiBlurDummyText : aiComment;
    final cardChild = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AbsorbPointer(
            child: cardChild,
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black38,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      'Pro 버전에서 확인 가능',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('구독하기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      
      // ProfileScreen 캘린더 즉시 갱신 (저장 성공 시)
      ref.read(plannedWorkoutsRefreshProvider.notifier).state++;
      
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
    // weeklyVolume의 키에서 주의 시작일을 찾거나, 첫 번째 키를 사용
    final weekStartKeys = weeklyVolume.keys.toList()..sort();
    if (weekStartKeys.isEmpty) {
      // 데이터가 없는 경우 빈 차트 표시
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek =
          today.subtract(Duration(days: now.weekday - 1));
      final days =
          List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
      final values = List.filled(7, 0.0);
      return _buildChart(context, days, values);
    }
    
    // 주의 시작일(월요일) 찾기
    final firstKey = weekStartKeys.first;
    final startOfWeek = DateTime(firstKey.year, firstKey.month, firstKey.day);
    final days =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final values = days.map((d) => weeklyVolume[d] ?? 0.0).toList();
    return _buildChart(context, days, values);
  }

  Widget _buildChart(BuildContext context, List<DateTime> days, List<double> values) {
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
  final bool isCurrentWeek;
  final Widget child;
  final IconData icon; // 추가
  final String message; // 추가

  const _PremiumGate({
    required this.isPremium,
    required this.isCurrentWeek,
    required this.child,
    this.icon = Icons.lock, // 기본값
    this.message = '과거 기록 분석은 프리미엄 기능입니다.', // 기본값
  });

  @override
  Widget build(BuildContext context) {
    // 잠금 조건: !isPremium && !isCurrentWeek
    // 이번 주이거나 프리미엄이면 차트 표시
    if (isPremium || isCurrentWeek) return child;

    // 과거 주이고 프리미엄이 아니면 잠금 UI 표시
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black45, // 약간 더 진한 오버레이
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32, color: Colors.white), // 맞춤형 아이콘
                  const SizedBox(height: 12),
                  Text(
                    message, // 맞춤형 메시지
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // 흰색 텍스트
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ], // 옅은 그림자 추가
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // CTA 버튼: "프리미엄 구독하고 전체 기록 보기"
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('프리미엄 구독하고 전체 기록 보기'),
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
