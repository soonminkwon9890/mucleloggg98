import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/workout_set.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../../data/models/planned_workout.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../widgets/workout/routine_generation_dialog.dart';

/// 운동 분석 화면
class WorkoutAnalysisScreen extends ConsumerStatefulWidget {
  final String exerciseName;

  const WorkoutAnalysisScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  ConsumerState<WorkoutAnalysisScreen> createState() =>
      _WorkoutAnalysisScreenState();
}

class _WorkoutAnalysisScreenState extends ConsumerState<WorkoutAnalysisScreen> {
  // 날짜별 세트 데이터
  Map<String, List<WorkoutSet>>? _historyByDate;
  Map<String, String?>? _difficultyByDate; // [추가] 날짜별 강도 데이터
  bool _isLoadingHistory = false;
  String? _historyError;

  // 차트 데이터
  List<FlSpot>? _chartSpots;
  Map<int, String>? _xAxisLabels; // 인덱스 -> 날짜 문자열

  // 루틴 생성 관련 상태
  bool _isGeneratingRoutine = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// 날짜별 세트 데이터 로딩
  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final history =
          await repository.getHistoryByExerciseName(widget.exerciseName);
      final difficultyMap =
          await repository.getDifficultyByExerciseName(widget.exerciseName); // [추가]

      // [안전핀] UI 레벨에서 정렬 보장 (오래된 순 -> 최신 순)
      // Repository에서 정렬되어 있어도 UI 레벨에서 한 번 더 확인하여 안전성 확보
      for (var key in history.keys) {
        history[key]!.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return a.createdAt!.compareTo(b.createdAt!); // 오래된 순 -> 최신 순
        });
      }

      if (mounted) {
        setState(() {
          _historyByDate = history;
          _difficultyByDate = difficultyMap; // [추가]
          _isLoadingHistory = false;
        });
        // 차트 데이터 준비
        _prepareChartData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _isLoadingHistory = false;
        });
      }
    }
  }

  /// 단순 Epley 공식: 1RM = 무게 * (1 + (0.0333 * 횟수))
  /// WorkoutRecommendationService를 사용하도록 변경
  double _calculateOneRepMax(double weight, int reps) {
    return WorkoutRecommendationService.calculateOneRepMax(weight, reps);
  }

  /// 특정 날짜의 세트들 중 최고 1RM 값 반환
  double? _getMax1RMForDate(List<WorkoutSet> sets) {
    if (sets.isEmpty) return null;

    double max1RM = 0.0;
    for (final set in sets) {
      final oneRM = _calculateOneRepMax(set.weight, set.reps);
      if (oneRM > max1RM) {
        max1RM = oneRM;
      }
    }
    return max1RM;
  }

  /// 차트 데이터 준비
  void _prepareChartData() {
    if (_historyByDate == null || _historyByDate!.isEmpty) {
      _chartSpots = null;
      _xAxisLabels = null;
      return;
    }

    // 날짜순 정렬 (과거 -> 현재)
    final sortedEntries = _historyByDate!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 0; i < sortedEntries.length; i++) {
      final dateKey = sortedEntries[i].key;
      final sets = sortedEntries[i].value;
      final max1RM = _getMax1RMForDate(sets);

      if (max1RM != null) {
        spots.add(FlSpot(i.toDouble(), max1RM));
        // 날짜 포맷: MM.dd (intl 패키지 사용)
        final date = DateTime.parse(dateKey);
        labels[i] = DateFormat('MM.dd').format(date);
      }
    }

    setState(() {
      _chartSpots = spots;
      _xAxisLabels = labels;
    });
  }

  /// 날짜별 리스트 UI 빌드 (Sliver)
  Widget _buildHistoryList() {
    if (_historyByDate == null || _historyByDate!.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('기록된 운동이 없습니다'),
          ),
        ),
      );
    }

    final sortedDates = _historyByDate!.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신순

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dateKey = sortedDates[index];
          final sets = _historyByDate![dateKey]!;

          final totalVolume =
              sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
          final totalReps = sets.fold(0, (sum, set) => sum + set.reps);

          return Dismissible(
            key: Key('date_$dateKey'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('기록 삭제'),
                      content: Text('$dateKey의 기록을 삭제하시겠습니까?'),
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
                  ) ??
                  false;
            },
            onDismissed: (direction) async {
              await _deleteDateRecords(dateKey);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Row(
                  children: [
                    Text(dateKey),
                    const SizedBox(width: 8),
                    _buildDifficultyTag(_difficultyByDate?[dateKey]),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('총 볼륨: ${totalVolume.toStringAsFixed(1)}kg'),
                    Text('총 횟수: $totalReps회'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteConfirmation(dateKey),
                ),
              ),
            ),
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }

  /// Difficulty 태그 위젯 빌드
  Widget _buildDifficultyTag(String? difficulty) {
    if (difficulty == null) return const SizedBox.shrink();
    
    String text;
    Color color;
    switch (difficulty) {
      case 'easy':
        text = '😀 쉬움';
        color = Colors.green;
        break;
      case 'hard':
        text = '🥵 어려움';
        color = Colors.red;
        break;
      case 'normal':
      default:
        text = '😐 보통';
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 1RM 성장 추이 차트 위젯
  Widget _buildTrendChart() {
    if (_chartSpots == null || _chartSpots!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('데이터가 쌓이면 성장 그래프가 표시됩니다'),
          ),
        ),
      );
    }

    final spots = _chartSpots!;
    final spotsLength = spots.length;

    // Single Point 처리: 데이터가 1개일 경우 minX, maxX 조정
    final minX = spotsLength == 1 ? -0.5 : 0.0;
    final maxX = spotsLength == 1 ? 0.5 : (spotsLength - 1).toDouble();

    // Interval 동적 조정: 데이터 개수에 따라 간격 설정
    int interval = 1;
    if (spotsLength > 15) {
      interval = 3;
    } else if (spotsLength > 7) {
      interval = 2;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1RM 성장 추이',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: const FlDotData(show: true),
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}kg',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      axisNameWidget: const Text(
                        '1RM (kg)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: interval.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || _xAxisLabels?[index] == null) {
                            return const Text('');
                          }
                          return Text(
                            _xAxisLabels![index]!,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots.map((spot) {
                          final dateIndex = spot.x.toInt();
                          final dateLabel = _xAxisLabels?[dateIndex] ?? '';
                          return LineTooltipItem(
                            '$dateLabel: ${spot.y.toInt()}kg',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
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

  /// 타겟 부위 정보 표시 위젯
  Widget _buildTargetMusclesChip() {
    // ExerciseBaseline 정보 가져오기
    // (Repository에서 exerciseName으로 조회)
    return FutureBuilder<ExerciseBaseline?>(
      future: _getBaseline(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.targetMuscles == null) {
          return const SizedBox.shrink();
        }

        final targetMuscles = snapshot.data!.targetMuscles!;
        if (targetMuscles.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '타겟 부위',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: targetMuscles
                      .map((muscle) => Chip(
                            label: Text(muscle),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Baseline 정보 가져오기
  Future<ExerciseBaseline?> _getBaseline() async {
    final repository = ref.read(workoutRepositoryProvider);
    final baselines = await repository.getBaselines();
    try {
      return baselines.firstWhere(
        (b) => b.exerciseName == widget.exerciseName,
      );
    } catch (e) {
      return null;
    }
  }

  /// 날짜별 기록 삭제
  Future<void> _deleteDateRecords(String dateKey) async {
    if (_historyByDate == null) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final date = DateTime.parse(dateKey);

      // baselineId를 찾아야 함 (첫 번째 세트의 baselineId 사용)
      final sets = _historyByDate![dateKey];
      if (sets == null || sets.isEmpty) return;

      final baselineId = sets.first.baselineId;

      // Repository 메서드 호출
      await repository.deleteWorkoutSetsByDate(baselineId, date);

      // 로컬 상태 업데이트
      setState(() {
        _historyByDate!.remove(dateKey);
        if (_historyByDate!.isEmpty) {
          _historyByDate = {};
        }
      });

      // Provider 갱신 (다른 화면 동기화)
      ref.invalidate(baselinesProvider);
      ref.invalidate(archivedBaselinesProvider);
      ref.invalidate(workoutDatesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 삭제 확인 다이얼로그 표시
  Future<void> _showDeleteConfirmation(String dateKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('$dateKey의 기록을 삭제하시겠습니까?'),
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

    if (confirmed == true) {
      await _deleteDateRecords(dateKey);
    }
  }

  /// 다음 주 루틴 생성
  Future<void> _generateNextWeekRoutine() async {
    setState(() => _isGeneratingRoutine = true);
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
      
      // 1. 지난주 데이터 및 목표 조회
      final sessions = await repo.getLastWeekSessions();
      if (sessions.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          setState(() => _isGeneratingRoutine = false);
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
      
      // 2. Baseline 매핑
      final baselineIds = sessions.map((s) => s.baselineId).toSet().toList();
      final baselines = await repo.getBaselinesByIds(baselineIds);
      final baselineMap = {for (var b in baselines) b.id: b};
      
      // 3. Best Set 데이터 준비 (병렬 처리)
      final bestSetsFutures = sessions.map((s) async {
        // [주의] Part 1에서 만든 메서드 이름 확인: getLastWeekBestSet
        final bestSet = await repo.getLastWeekBestSet(s.baselineId, s.workoutDate);
        return MapEntry(s.baselineId, bestSet);
      }).toList();
      
      final bestSetsMap = Map.fromEntries(await Future.wait(bestSetsFutures));
      
      // 4. 서비스 호출 (Gemini API 우선, 실패 시 폴백)
      final plans = await WorkoutRecommendationService.generateWeeklyPlan(
        lastWeekSessions: sessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: bestSetsMap, // 이름 매칭 확인
      );
      
      // 5. 로딩 다이얼로그 닫고 결과 표시
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        setState(() => _isGeneratingRoutine = false);
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
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        setState(() => _isGeneratingRoutine = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  /// 다이얼로그에서 반환된 루틴을 캘린더에 저장 (단 하루에 일괄 저장)
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
          exerciseName: dto.exerciseName, // 운동 이름 매핑
          isConvertedToLog: false, // 초기값: 아직 변환 안 됨
          createdAt: DateTime.now(),
          colorHex: colorHex,
        );
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          // 로딩 중일 때는 CircularProgressIndicator 표시
          if (_isGeneratingRoutine)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI 루틴 생성',
              onPressed: _generateNextWeekRoutine,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingHistory
            ? const Center(child: CircularProgressIndicator())
            : _historyError != null
                ? Center(child: Text('오류: $_historyError'))
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildTrendChart(),
                                const SizedBox(height: 16),
                                _buildTargetMusclesChip(),
                                const SizedBox(height: 16),
                                const Text(
                                  '날짜별 기록',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildHistoryList(),
                      ],
                    ),
                  ),
      ),
    );
  }
}
