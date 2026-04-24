import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../utils/premium_guidance_dialog.dart';
import '../management/management_screen.dart';

/// 운동 분석 탭 메인 화면 (대시보드)
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  // ── 주간 상태 ──────────────────────────────────────────────────────────────
  late DateTime _selectedWeekStart;

  // ── 월간 상태 ──────────────────────────────────────────────────────────────
  late DateTime _selectedMonthStart;

  // ── 토글 상태 ─────────────────────────────────────────────────────────────
  bool _isMonthlyView = false;

  // ── 정규화 헬퍼 ───────────────────────────────────────────────────────────

  /// 주의 시작일을 날짜(00:00:00)로 정규화 (Provider 캐시 키 안정성)
  static DateTime _normalizeWeekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// 월의 시작일(1일)로 정규화 (Provider 캐시 키 안정성)
  static DateTime _normalizeMonthStart(DateTime d) =>
      DateTime(d.year, d.month, 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    _selectedWeekStart =
        _normalizeWeekStart(todayLocal.subtract(Duration(days: now.weekday - 1)));
    _selectedMonthStart = _normalizeMonthStart(now);
  }

  // ── 주간 헬퍼 ─────────────────────────────────────────────────────────────

  bool _isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final currentWeekStart =
        todayLocal.subtract(Duration(days: now.weekday - 1));
    final dateNorm = DateTime(date.year, date.month, date.day);
    final cwsNorm = DateTime(
        currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    return dateNorm.year == cwsNorm.year &&
        dateNorm.month == cwsNorm.month &&
        dateNorm.day == cwsNorm.day;
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormatter.formatDate(weekStart)} ~ ${DateFormatter.formatMonthDay(weekEnd)}';
  }

  bool _canMoveToNextWeek() {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final currentWeekStart =
        todayLocal.subtract(Duration(days: now.weekday - 1));
    return _selectedWeekStart.isBefore(currentWeekStart);
  }

  // ── 월간 헬퍼 ─────────────────────────────────────────────────────────────

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  String _formatMonthLabel(DateTime monthStart) =>
      '${monthStart.year}년 ${monthStart.month}월';

  bool _canMoveToNextMonth() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    return _selectedMonthStart.isBefore(currentMonthStart);
  }

  DateTime _previousMonth(DateTime d) =>
      d.month == 1 ? DateTime(d.year - 1, 12, 1) : DateTime(d.year, d.month - 1, 1);

  DateTime _nextMonth(DateTime d) =>
      d.month == 12 ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);

  // ── 공통 UI 부품 ──────────────────────────────────────────────────────────

  /// 라이브러리 버튼 (내 보관함)
  Widget _buildLibraryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManagementScreen(isSelectionMode: false),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.view_list_rounded,
                        color: Colors.blueAccent, size: 26),
                  ),
                ),
                const Expanded(
                  child: Text(
                    '나만의 운동 라이브러리',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child:
                        Icon(Icons.chevron_right, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 날짜 네비게이터 — 주간 또는 월간 모드에 따라 전환
  Widget _buildDateNavigator(BuildContext context) {
    if (_isMonthlyView) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonthStart =
                        _previousMonth(_selectedMonthStart);
                  });
                },
              ),
              Text(
                _formatMonthLabel(_selectedMonthStart),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _canMoveToNextMonth()
                      ? Theme.of(context).iconTheme.color
                      : Theme.of(context).disabledColor,
                ),
                onPressed: _canMoveToNextMonth()
                    ? () {
                        setState(() {
                          _selectedMonthStart =
                              _nextMonth(_selectedMonthStart);
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    // 주간 네비게이터
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedWeekStart = _normalizeWeekStart(
                      _selectedWeekStart.subtract(const Duration(days: 7)));
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
                        _selectedWeekStart = _normalizeWeekStart(
                            _selectedWeekStart
                                .add(const Duration(days: 7)));
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 주간/월간 세그먼트 토글
  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleSegment('주간', !_isMonthlyView),
              _buildToggleSegment('월간', _isMonthlyView),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSegment(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final wantMonthly = label == '월간';
        if (wantMonthly != _isMonthlyView) {
          setState(() => _isMonthlyView = wantMonthly);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 에러 UI (재시도 버튼 포함)
  Widget _buildErrorUI(
      BuildContext context, Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 빌드 ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final normalizedWeekStart = _normalizeWeekStart(_selectedWeekStart);
    final normalizedMonthStart = _normalizeMonthStart(_selectedMonthStart);

    final authStateAsync = ref.watch(authStateProvider);
    // 두 프로바이더를 모두 watch하여 토글 전환 시 즉시 데이터가 준비됨
    final weeklyStatsAsync =
        ref.watch(dashboardStatsProvider(normalizedWeekStart));
    final monthlyStatsAsync =
        ref.watch(monthlyDashboardStatsProvider(normalizedMonthStart));

    final isPremium = ref.watch(subscriptionProvider).isPremium;
    final isCurrentWeek = _isCurrentWeek(_selectedWeekStart);
    final isCurrentMonth = _isCurrentMonth(_selectedMonthStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
      ),
      body: SafeArea(
        child: authStateAsync.when(
          data: (isAuthenticated) {
            if (!isAuthenticated) {
              return const Center(child: Text('로그인이 필요합니다'));
            }

            // ── 월간 뷰 ────────────────────────────────────────────────────
            if (_isMonthlyView) {
              return monthlyStatsAsync.when(
                data: (stats) {
                  final aiComment = _buildAiComment(stats.bodyBalance);
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(
                          monthlyDashboardStatsProvider(normalizedMonthStart));
                      await ref.read(monthlyDashboardStatsProvider(
                              normalizedMonthStart)
                          .future);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLibraryButton(context),
                          _buildDateNavigator(context),
                          _buildPeriodToggle(),
                          _PremiumGate(
                            isPremium: isPremium,
                            isCurrentPeriod: isCurrentMonth,
                            icon: Icons.show_chart,
                            message: '지난 성장 그래프를 확인하고 정체기를 돌파하세요!',
                            onPremiumPurchased: () =>
                                ref.invalidate(subscriptionProvider),
                            child: MonthlyVolumeChartCard(
                                monthlyVolume: stats.weeklyGroupedVolume),
                          ),
                          const SizedBox(height: 12),
                          _PremiumGate(
                            isPremium: isPremium,
                            isCurrentPeriod: isCurrentMonth,
                            icon: Icons.pie_chart,
                            message: '신체 불균형을 분석하여 완벽한 밸런스를 찾으세요.',
                            onPremiumPurchased: () =>
                                ref.invalidate(subscriptionProvider),
                            child: BodyBalanceChartCard(
                              key: ValueKey(
                                  'balance_month_${normalizedMonthStart.toIso8601String()}'),
                              bodyBalance: stats.bodyBalance,
                              title: '월간 부위별 밸런스',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAiCommentCard(
                            context,
                            aiComment: aiComment,
                            isPremium: isPremium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorUI(
                  context,
                  error,
                  () => ref.invalidate(
                      monthlyDashboardStatsProvider(normalizedMonthStart)),
                ),
              );
            }

            // ── 주간 뷰 ────────────────────────────────────────────────────
            return weeklyStatsAsync.when(
              data: (stats) {
                final weeklyVolume = stats.weeklyVolume;
                final bodyBalance = stats.bodyBalance;
                final aiComment = _buildAiComment(bodyBalance);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        dashboardStatsProvider(normalizedWeekStart));
                    await ref.read(
                        dashboardStatsProvider(normalizedWeekStart).future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLibraryButton(context),
                        _buildDateNavigator(context),
                        _buildPeriodToggle(),
                        _PremiumGate(
                          isPremium: isPremium,
                          isCurrentPeriod: isCurrentWeek,
                          icon: Icons.show_chart,
                          message: '지난 성장 그래프를 확인하고 정체기를 돌파하세요!',
                          onPremiumPurchased: () =>
                              ref.invalidate(subscriptionProvider),
                          child: WeeklyVolumeChartCard(
                              weeklyVolume: weeklyVolume),
                        ),
                        const SizedBox(height: 12),
                        _PremiumGate(
                          isPremium: isPremium,
                          isCurrentPeriod: isCurrentWeek,
                          icon: Icons.pie_chart,
                          message: '신체 불균형을 분석하여 완벽한 밸런스를 찾으세요.',
                          onPremiumPurchased: () =>
                              ref.invalidate(subscriptionProvider),
                          child: BodyBalanceChartCard(
                            key: ValueKey(
                                'balance_week_${normalizedWeekStart.toIso8601String()}'),
                            bodyBalance: bodyBalance,
                            title: '주간 부위별 밸런스',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAiCommentCard(
                          context,
                          aiComment: aiComment,
                          isPremium: isPremium,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorUI(
                context,
                error,
                () => ref.invalidate(
                    dashboardStatsProvider(normalizedWeekStart)),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('인증 오류: $error')),
        ),
      ),
    );
  }

  // ── AI 코멘트 ─────────────────────────────────────────────────────────────

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
          child: Text(aiComment, style: const TextStyle(fontSize: 15)),
        ),
      );
    }

    final displayText =
        aiComment.trim().isEmpty ? _aiBlurDummyText : aiComment;
    final cardChild = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(displayText, style: const TextStyle(fontSize: 15)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AbsorbPointer(child: cardChild),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final isPurchased =
                            await showPremiumGuidanceDialog(context);
                        if (isPurchased == true && context.mounted) {
                          ref.invalidate(subscriptionProvider);
                        }
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
    const axisKeys = [
      '가슴', '등', '어깨', '이두', '삼두', '코어',
      '대퇴사두', '햄스트링', '둔근', '종아리',
    ];
    const axisLabels = [
      '가슴', '등', '어깨', '이두', '삼두', '코어',
      '대퇴사두(앞)', '햄스트링(뒤)', '둔근(힙)', '종아리',
    ];

    final values = axisKeys.map((k) => bodyBalance[k] ?? 0.0).toList();
    final maxVal = values.fold<double>(0.0, (p, c) => c > p ? c : p);
    if (maxVal <= 0) return '운동 기록이 부족합니다.';

    double sumByKeys(List<String> keys) =>
        keys.fold<double>(0.0, (sum, k) => sum + (bodyBalance[k] ?? 0.0));

    const upperKeys = ['가슴', '등', '어깨', '이두', '삼두', '코어'];
    const lowerKeys = ['대퇴사두', '햄스트링', '둔근', '종아리'];
    final upperTotal = sumByKeys(upperKeys);
    final lowerTotal = sumByKeys(lowerKeys);
    const ratioThreshold = 1.5;

    if (lowerTotal >= upperTotal * ratioThreshold) {
      return '하체 비중이 높습니다. 전반적인 상체 운동을 보강해 보세요.';
    }
    if (upperTotal >= lowerTotal * ratioThreshold) {
      return '상체 비중이 높습니다. 하체 운동 밸런스를 맞춰보세요.';
    }

    final minVal =
        values.fold<double>(double.infinity, (p, c) => c < p ? c : p);
    final minIdx = values.indexOf(minVal);
    return '${axisLabels[minIdx]} 운동이 가장 부족해요.';
  }
}

// =============================================================================
// 주간 볼륨 바 차트
// =============================================================================

class WeeklyVolumeChartCard extends StatelessWidget {
  final Map<DateTime, double> weeklyVolume;

  const WeeklyVolumeChartCard({super.key, required this.weeklyVolume});

  @override
  Widget build(BuildContext context) {
    final weekStartKeys = weeklyVolume.keys.toList()..sort();
    if (weekStartKeys.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
      return _buildChart(context, days, List.filled(7, 0.0));
    }

    final firstKey = weekStartKeys.first;
    final startOfWeek =
        DateTime(firstKey.year, firstKey.month, firstKey.day);
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final values = days.map((d) => weeklyVolume[d] ?? 0.0).toList();
    return _buildChart(context, days, values);
  }

  Widget _buildChart(
      BuildContext context, List<DateTime> days, List<double> values) {
    final maxY = values.fold<double>(0.0, (p, c) => c > p ? c : p);
    final chartMaxY = maxY <= 0 ? 10.0 : maxY * 1.2;
    const barColor = Color(0xFFAEC4F8);
    const backColor = Color(0xFF333333);
    final fmt = NumberFormat('#,###');

    final barGroups = <BarChartGroupData>[
      for (int i = 0; i < days.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              color: barColor,
              width: 26,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: chartMaxY,
                color: backColor,
              ),
            ),
          ],
        ),
    ];

    String weekdayKo(DateTime d) {
      switch (d.weekday) {
        case DateTime.monday:    return '월';
        case DateTime.tuesday:   return '화';
        case DateTime.wednesday: return '수';
        case DateTime.thursday:  return '목';
        case DateTime.friday:    return '금';
        case DateTime.saturday:  return '토';
        case DateTime.sunday:    return '일';
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
              '주간 총 운동 볼륨 (Kg)',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                            child: Text(weekdayKo(days[idx]),
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final v = rod.toY;
                        if (v <= 0) return null;
                        return BarTooltipItem(
                          fmt.format(v.toInt()),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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

// =============================================================================
// 월간 볼륨 바 차트 (1주차~5주차)
// =============================================================================

class MonthlyVolumeChartCard extends StatelessWidget {
  /// 키: 1~5 (주차), 값: 해당 주차 총 볼륨(kg)
  final Map<int, double> monthlyVolume;

  const MonthlyVolumeChartCard({super.key, required this.monthlyVolume});

  @override
  Widget build(BuildContext context) {
    const weekLabels = ['1주차', '2주차', '3주차', '4주차', '5주차'];
    final values =
        [1, 2, 3, 4, 5].map((w) => monthlyVolume[w] ?? 0.0).toList();
    final maxY = values.fold<double>(0.0, (p, c) => c > p ? c : p);
    final chartMaxY = maxY <= 0 ? 10.0 : maxY * 1.2;
    const barColor = Color(0xFFAEC4F8);
    const backColor = Color(0xFF333333);
    final fmt = NumberFormat('#,###');

    final barGroups = <BarChartGroupData>[
      for (int i = 0; i < 5; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              color: barColor,
              width: 36,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: chartMaxY,
                color: backColor,
              ),
            ),
          ],
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '월간 총 운동 볼륨 (Kg)',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= weekLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(weekLabels[idx],
                                style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final v = rod.toY;
                        if (v <= 0) return null;
                        return BarTooltipItem(
                          fmt.format(v.toInt()),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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

// =============================================================================
// 부위별 밸런스 레이더 차트
// =============================================================================

class BodyBalanceChartCard extends StatelessWidget {
  final Map<String, double> bodyBalance;

  /// 카드 상단 제목 — 주간: '주간 부위별 밸런스', 월간: '월간 부위별 밸런스'
  final String title;

  const BodyBalanceChartCard({
    super.key,
    required this.bodyBalance,
    this.title = '부위별 밸런스',
  });

  static const _axisKeys = [
    '가슴', '등', '어깨', '이두', '삼두', '코어',
    '대퇴사두', '햄스트링', '둔근', '종아리',
  ];

  static const _axisLabels = [
    '가슴', '등', '어깨', '이두', '삼두', '코어',
    '대퇴사두(앞)', '햄스트링(뒤)', '둔근(힙)', '종아리',
  ];

  @override
  Widget build(BuildContext context) {
    final values = _axisKeys.map((k) => bodyBalance[k] ?? 0.0).toList();
    final maxVal = values.fold<double>(0.0, (p, c) => c > p ? c : p);
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
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: RadarChart(
                RadarChartData(
                  radarBackgroundColor: Colors.transparent,
                  radarShape: RadarShape.polygon,
                  radarBorderData: const BorderSide(
                    color: Colors.white24,
                    width: 1,
                  ),
                  tickBorderData: const BorderSide(
                    color: Colors.white24,
                    width: 1,
                  ),
                  gridBorderData: const BorderSide(
                    color: Colors.white24,
                    width: 1,
                  ),
                  titleTextStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  titlePositionPercentageOffset: 0.2,
                  tickCount: 1,
                  getTitle: (index, angle) =>
                      RadarChartTitle(text: _axisLabels[index]),
                  dataSets: [
                    RadarDataSet(
                      fillColor:
                          const Color(0xFFAEC4F8).withValues(alpha: 0.4),
                      borderColor: const Color(0xFFAEC4F8),
                      entryRadius: 3,
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

// =============================================================================
// 프리미엄 게이트 (과거 기간 잠금)
// =============================================================================

class _PremiumGate extends StatelessWidget {
  final bool isPremium;

  /// 현재 보고 있는 기간이 "현재 주" 또는 "현재 월"이면 true → 잠금 해제
  final bool isCurrentPeriod;
  final Widget child;
  final IconData icon;
  final String message;
  final VoidCallback? onPremiumPurchased;

  const _PremiumGate({
    required this.isPremium,
    required this.isCurrentPeriod,
    required this.child,
    this.icon = Icons.lock,
    this.message = '과거 기록 분석은 프리미엄 기능입니다.',
    this.onPremiumPurchased,
  });

  @override
  Widget build(BuildContext context) {
    // 프리미엄이거나 현재 기간이면 차트 표시
    if (isPremium || isCurrentPeriod) return child;

    // 과거 기간이고 비프리미엄 → 잠금 UI
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black45,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black
                                  .withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final isPurchased =
                          await showPremiumGuidanceDialog(context);
                      if (isPurchased == true && context.mounted) {
                        onPremiumPurchased?.call();
                      }
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
