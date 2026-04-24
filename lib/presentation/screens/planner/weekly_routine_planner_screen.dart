import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planned_workout.dart';
import '../../../data/models/planner_models.dart';
import '../../../domain/algorithms/workout_recommendation_service.dart';
import '../../providers/weekly_planner_provider.dart';
import '../../providers/workout_provider.dart';

// =============================================================================
// WeeklyRoutinePlannerScreen
// =============================================================================

/// AI 가 제안한 주간 운동 계획을 드래그 앤 드롭으로 편집하고 캘린더에 저장하는 화면.
///
/// [selectedBaselineIds] — 분석 대상 운동 baseline ID 집합.
///                         비어있으면 지난주 전체 기록을 사용합니다.
class WeeklyRoutinePlannerScreen extends ConsumerStatefulWidget {
  final Set<String> selectedBaselineIds;

  const WeeklyRoutinePlannerScreen({
    super.key,
    required this.selectedBaselineIds,
  });

  @override
  ConsumerState<WeeklyRoutinePlannerScreen> createState() =>
      _WeeklyRoutinePlannerScreenState();
}

class _WeeklyRoutinePlannerScreenState
    extends ConsumerState<WeeklyRoutinePlannerScreen> {
  // UI 상태
  bool _isLoading = false;   // 탭으로 직접 임베딩 — 초기에 로딩 없이 빈 그리드 표시
  bool _isSaving = false;
  bool _hasRunAnalysis = false; // AI 분석이 한 번 이상 실행된 적 있는지
  bool _isNextWeek = true; // 다음 주(true) 또는 이번 주(false) 루틴 분석 여부
  String? _errorMessage;
  String? _errorSubMessage;

  // 요약 통계
  int _totalSessions = 0;
  double _totalVolume = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlanner());
  }

  // ---------------------------------------------------------------------------
  // 초기화: 기존 데이터 유무 확인 후 AI 로딩 결정
  // ---------------------------------------------------------------------------

  void _initPlanner() {
    // 기존 카드가 있으면(지난 세션 유지) 분석 완료 상태로 표시
    final hasExistingCards =
        ref.read(weeklyPlannerProvider).any((d) => d.cards.isNotEmpty);
    if (hasExistingCards) {
      setState(() {
        _isLoading = false;
        _hasRunAnalysis = true;
      });
    }
    // 없으면 _isLoading = false, _hasRunAnalysis = false → 빈 그리드 + CTA 표시
  }

  // ---------------------------------------------------------------------------
  // AI 분석 및 플래너 초기화
  // ---------------------------------------------------------------------------

  Future<void> _loadAiPlan({bool isNextWeek = true}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasRunAnalysis = true;
      _isNextWeek = isNextWeek;
      _errorMessage = null;
      _errorSubMessage = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);

      final allSessions = await repo.getLastWeekSessions(isNextWeek: isNextWeek);
      final sessions = widget.selectedBaselineIds.isEmpty
          ? allSessions
          : allSessions
              .where((s) =>
                  widget.selectedBaselineIds.contains(s.baselineId))
              .toList();

      if (!mounted) return;

      if (sessions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = isNextWeek
              ? '선택한 운동의 이번주 기록이 없습니다.'
              : '선택한 운동의 지난주 기록이 없습니다.';
          _errorSubMessage = '먼저 운동을 기록해 주세요.';
        });
        return;
      }

      _totalSessions = sessions.length;
      _totalVolume =
          sessions.fold(0.0, (sum, s) => sum + (s.totalVolume ?? 0.0));

      final userGoal = await repo.getUserGoal();
      final baselineIds = sessions.map((s) => s.baselineId).toSet().toList();
      final baselines = await repo.getBaselinesByIds(baselineIds);
      final baselineMap = {for (final b in baselines) b.id: b};

      final bestSetsFutures = sessions.map((s) async {
        final bestSet =
            await repo.getLastWeekBestSet(s.baselineId, s.workoutDate);
        final dateStr = DateFormat('yyyy-MM-dd').format(s.workoutDate);
        return MapEntry('${s.baselineId}_$dateStr', bestSet);
      }).toList();
      final bestSetsMap =
          Map.fromEntries(await Future.wait(bestSetsFutures));

      final validSessions = sessions.where((s) {
        final dateStr = DateFormat('yyyy-MM-dd').format(s.workoutDate);
        return bestSetsMap['${s.baselineId}_$dateStr'] != null;
      }).toList();

      if (!mounted) return;

      if (validSessions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '완료된 세트 기록이 없습니다.\n운동을 완료한 뒤 다시 시도해 주세요.';
        });
        return;
      }

      final plans = await WorkoutRecommendationService.generateWeeklyPlan(
        lastWeekSessions: validSessions,
        userGoal: userGoal,
        baselineMap: baselineMap,
        bestSetsMap: bestSetsMap,
      );

      if (!mounted) return;

      if (plans.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'AI가 추천 운동을 생성하지 못했습니다.\n지난주 운동 기록을 확인해 주세요.';
        });
        return;
      }

      // AI는 session.workoutDate + 7로 대상 날짜를 이미 정확하게 계산하므로
      // 추가 날짜 조정 불필요. isNextWeek 여부와 관계없이 그대로 사용.
      ref.read(weeklyPlannerProvider.notifier).loadFromPlans(plans);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'AI 분석 중 오류가 발생했습니다.\n$e';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 인터랙션: 편집 다이얼로그
  // ---------------------------------------------------------------------------

  Future<void> _showEditDialog(PlannerExerciseCard card) async {
    final nameCtrl = TextEditingController(text: card.exerciseName);
    final weightCtrl =
        TextEditingController(text: card.targetWeight.toStringAsFixed(1));
    final repsCtrl = TextEditingController(text: card.targetReps.toString());
    final setsCtrl = TextEditingController(text: card.targetSets.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '운동명',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      decoration: const InputDecoration(
                        labelText: '무게',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      decoration: const InputDecoration(
                        labelText: '횟수',
                        suffixText: '회',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      decoration: const InputDecoration(
                        labelText: '세트',
                        suffixText: '세트',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    final newName = nameCtrl.text.trim();
    final newWeight = double.tryParse(weightCtrl.text);
    final newReps = int.tryParse(repsCtrl.text);
    final newSets = int.tryParse(setsCtrl.text);

    nameCtrl.dispose();
    weightCtrl.dispose();
    repsCtrl.dispose();
    setsCtrl.dispose();

    if (confirmed != true || !mounted) return;

    ref.read(weeklyPlannerProvider.notifier).editCard(
          card.key,
          exerciseName: newName.isEmpty ? card.exerciseName : newName,
          targetWeight: newWeight ?? card.targetWeight,
          targetReps: newReps ?? card.targetReps,
          targetSets: newSets ?? card.targetSets,
        );
  }

  // ---------------------------------------------------------------------------
  // 인터랙션: 삭제
  // ---------------------------------------------------------------------------

  void _deleteCard(Key cardKey, String exerciseName) {
    ref.read(weeklyPlannerProvider.notifier).deleteCard(cardKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$exerciseName이(가) 삭제되었습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 저장: Supabase planned_workouts 에 일괄 저장
  // ---------------------------------------------------------------------------

  Future<void> _savePlan() async {
    final days = ref.read(weeklyPlannerProvider);
    final hasCards = days.any((d) => d.cards.isNotEmpty);

    if (!hasCards) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장할 운동이 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // async gap 이전에 messenger 캡처 (use_build_context_synchronously 방지)
    final messenger = ScaffoldMessenger.of(context);

    try {
      const uuid = Uuid();
      const colorHex = '0xFF3F51B5';

      final plans = <PlannedWorkout>[];
      for (final day in days) {
        // AI가 계산한 날짜를 항상 로컬 자정으로 정규화하여 저장합니다.
        // _isNextWeek 플래그에 의존하지 않고 실제 날짜 값을 그대로 사용합니다.
        final scheduleDate =
            DateTime(day.date.year, day.date.month, day.date.day);
        for (final card in day.cards) {
          plans.add(PlannedWorkout(
            id: uuid.v4(),
            userId: '',
            baselineId: card.baselineId,
            scheduledDate: scheduleDate,
            targetWeight: card.targetWeight,
            targetReps: card.targetReps,
            targetSets: card.targetSets,
            aiComment: card.aiComment,
            isCompleted: false,
            exerciseName: card.exerciseName,
            isConvertedToLog: false,
            colorHex: colorHex,
            createdAt: DateTime.now(),
          ));
        }
      }

      await ref.read(workoutRepositoryProvider).savePlannedWorkouts(plans);

      if (!mounted) return;

      // 홈 화면 달력 즉시 갱신 (plannedWorkoutsRefreshProvider + homeViewModel 강제 리로드)
      ref.read(plannedWorkoutsRefreshProvider.notifier).state++;
      await ref.read(homeViewModelProvider.notifier).loadBaselines(forceRefresh: true);

      // 저장 완료 후 플래너 초기화 (다음 분석을 위해 빈 상태로 리셋)
      ref.read(weeklyPlannerProvider.notifier).reset();
      setState(() {
        _isSaving = false;      // Bug 3: 성공 경로에서도 반드시 false로 리셋
        _hasRunAnalysis = false;
        _totalSessions = 0;
        _totalVolume = 0;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('${plans.length}개의 운동이 캘린더에 저장되었습니다. 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 드래그 앤 드롭 콜백
  // ---------------------------------------------------------------------------

  /// 아이템 순서 변경 / 날짜 간 이동 처리.
  ///
  /// [drag_and_drop_lists] 패키지가 애니메이션을 완료한 뒤 호출합니다.
  /// Riverpod provider 를 업데이트하면 위젯이 리빌드되어 새 상태를 반영합니다.
  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    final days = ref.read(weeklyPlannerProvider);
    if (oldListIndex >= days.length || newListIndex >= days.length) return;
    if (oldItemIndex >= days[oldListIndex].cards.length) return;
    final card = days[oldListIndex].cards[oldItemIndex];
    ref
        .read(weeklyPlannerProvider.notifier)
        .placeCard(card.key, days[newListIndex].date, newItemIndex);
  }

  /// 리스트(요일 열) 순서는 변경 불가. 패키지 요구 시그니처를 위해 존재.
  void _onListReorder(int oldListIndex, int newListIndex) {
    // 월~일 열은 고정 순서. 아무 작업도 하지 않습니다.
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(weeklyPlannerProvider);
    final theme = Theme.of(context);

    final hasCards = days.any((d) => d.cards.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 루틴'),
        actions: [
          // 카드가 있을 때만 재분석 + 저장 버튼 표시
          if (!_isLoading && _errorMessage == null && hasCards) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'AI 재분석',
              onPressed: _isSaving
                  ? null
                  : () {
                      ref.read(weeklyPlannerProvider.notifier).reset();
                      _loadAiPlan(isNextWeek: _isNextWeek);
                    },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : _errorMessage != null
                ? _buildErrorView()
                : !_hasRunAnalysis || !hasCards
                    ? _buildEmptyCta()
                    : _buildPlannerView(days, theme),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 빈 상태 / CTA 뷰 (분석 전 초기 상태)
  // ---------------------------------------------------------------------------

  Widget _buildEmptyCta() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'AI 주간 루틴 플래너',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '지난주 운동 기록을 AI가 분석하여\n나에게 딱 맞는 다음 주 루틴을 만들어 드립니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _loadAiPlan(isNextWeek: false),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  '✨ 이번주 루틴 분석하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _loadAiPlan(isNextWeek: true),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  '✨ 다음주 루틴 분석하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 로딩 뷰
  // ---------------------------------------------------------------------------

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'AI가 주간 루틴을 분석 중입니다...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            '지난주 기록을 바탕으로 최적의 루틴을 만들고 있어요 ✨',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 에러 뷰
  // ---------------------------------------------------------------------------

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            if (_errorSubMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorSubMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(weeklyPlannerProvider.notifier).reset();
                setState(() {
                  _hasRunAnalysis = false;
                  _errorMessage = null;
                  _errorSubMessage = null;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 플래너 뷰 — DragAndDropLists
  // ---------------------------------------------------------------------------

  Widget _buildPlannerView(List<PlannerWorkoutDay> days, ThemeData theme) {
    return Column(
      children: [
        _SummaryHeader(
          totalSessions: _totalSessions,
          totalVolume: _totalVolume,
          totalCards: days.fold(0, (sum, d) => sum + d.cards.length),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                '카드를 길게 눌러 드래그 · 슬라이드 애니메이션으로 순서/날짜 변경',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: DragAndDropLists(
            // ── 상태 매핑 ──
            children: days
                .map((day) => _buildDragList(day, theme))
                .toList(),

            // ── 콜백 ──
            onItemReorder: _onItemReorder,
            onListReorder: _onListReorder,

            // ── 레이아웃: 수평 스크롤 칸반 보드 ──
            axis: Axis.horizontal,
            listWidth: 162,
            listPadding: const EdgeInsets.fromLTRB(4, 8, 4, 16),

            // ── 드래그 설정 ──
            itemDragOnLongPress: true,   // 길게 눌러야 드래그 시작
            listDragOnLongPress: false,  // 요일 열은 드래그 불가

            // ── 애니메이션 ──
            itemSizeAnimationDurationMilliseconds: 200,
            listSizeAnimationDurationMilliseconds: 200,

            // ── 고스트(드래그 중 원래 위치 플레이스홀더) ──
            itemGhostOpacity: 0.25,

            // ── 드롭 타겟 높이 (리스트 하단 빈 영역) ──
            lastItemTargetHeight: 56,
            addLastItemTargetHeightToTop: true,

            // ── 드래그 중 아이템 장식 ──
            itemDecorationWhileDragging: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        // ── 캘린더에 저장하기 버튼 (하단 고정) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _savePlan,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text(
                '캘린더에 저장하기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Riverpod 의 [PlannerWorkoutDay] 를 [DragAndDropList] 로 변환합니다.
  DragAndDropList _buildDragList(PlannerWorkoutDay day, ThemeData theme) {
    final weekday = day.date.weekday;
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[weekday - 1];
    final isWeekend = weekday >= 6;
    final headerColor = isWeekend
        ? Colors.red.withValues(alpha: 0.12)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
    final headerTextColor =
        isWeekend ? Colors.red[700]! : theme.colorScheme.primary;

    return DragAndDropList(
      // 요일 열은 고정 순서 — 드래그 비활성화
      canDrag: false,

      // ── 열 컨테이너 장식 ──
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),

      // ── 헤더: 요일 + 날짜 ──
      header: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: headerTextColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.date.month}/${day.date.day}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (day.cards.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${day.cards.length}개',
                style: TextStyle(fontSize: 10, color: headerTextColor),
              ),
            ],
          ],
        ),
      ),

      // ── 빈 열 안내 문구 ──
      // IgnorePointer: 드래그 중 플레이스홀더 텍스트가 DragTarget 히트 테스트를
      // 가로막지 않도록 포인터 이벤트를 투과시킵니다.
      contentsWhenEmpty: SizedBox(
        height: 80,
        child: Center(
          child: IgnorePointer(
            child: Text(
              '운동을\n드래그하세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ),
      ),

      // ── 아이템: PlannerExerciseCard → DragAndDropItem ──
      children: day.cards
          .map(
            (card) => DragAndDropItem(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: _ExerciseCardContent(
                  card: card,
                  onEdit: () => _showEditDialog(card),
                  onDelete: () =>
                      _deleteCard(card.key, card.exerciseName),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// =============================================================================
// _SummaryHeader
// =============================================================================

class _SummaryHeader extends StatelessWidget {
  final int totalSessions;
  final double totalVolume;
  final int totalCards;

  const _SummaryHeader({
    required this.totalSessions,
    required this.totalVolume,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 주간 루틴 분석 완료',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '지난 7일: $totalSessions회 운동 · '
                    '${totalVolume.toStringAsFixed(0)} kg 총 볼륨',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCards개 운동',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
// _ExerciseCardContent  —  순수 UI 카드 (Draggable 래핑 없음)
//
// drag_and_drop_lists 패키지가 전체 아이템을 드래그 대상으로 처리하므로
// 이 위젯은 시각적 표현만 담당합니다.
// =============================================================================

class _ExerciseCardContent extends StatelessWidget {
  final PlannerExerciseCard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCardContent({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 상단: 핸들 · 운동명 · 편집/삭제 ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.drag_handle,
                      size: 15, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    card.exerciseName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.edit_outlined,
                        size: 15, color: Colors.blueGrey),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline,
                        size: 15, color: Colors.redAccent),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // ── 목표: 무게 × 횟수 × 세트 ──
            Text(
              '${card.targetWeight % 1 == 0 ? card.targetWeight.toInt() : card.targetWeight}kg'
              ' × ${card.targetReps}회'
              ' × ${card.targetSets}세트',
              style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
            ),

            // ── AI 제안 태그 ──
            if (card.isAiProposed) ...[
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 9, color: Colors.amber[700]),
                    const SizedBox(width: 3),
                    Text(
                      'AI 제안',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
