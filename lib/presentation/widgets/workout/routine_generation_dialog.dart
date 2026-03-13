import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/workout_colors.dart';
import '../../../core/utils/adaptive_widgets.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/planned_workout_dto.dart';
import '../../providers/subscription_provider.dart';
import '../../../utils/premium_guidance_dialog.dart';

/// 강도 모드: High(+2.5kg), Normal(원본), Condition(85%), Maintain(유지)
enum RoutineIntensity { high, normal, condition, maintain }

/// 모드별 색상 (WorkoutColors 상수 사용)
const Map<RoutineIntensity, String> _intensityColorHex = {
  RoutineIntensity.high: WorkoutColors.highIntensityHex,
  RoutineIntensity.normal: WorkoutColors.normalHex,
  RoutineIntensity.condition: WorkoutColors.conditionHex,
  RoutineIntensity.maintain: WorkoutColors.maintainHex,
};

/// 다이얼로그 적용 결과 (날짜가 주입된 루틴 + 선택 색상)
class RoutineApplyResult {
  final List<PlannedWorkoutDto> routines;
  final String colorHex;
  /// [Phase 4] 유지 모드 여부 - true이면 지난주 운동을 다음 주로 복사
  final bool isMaintainMode;
  RoutineApplyResult(this.routines, this.colorHex, {this.isMaintainMode = false});
}

class RoutineGenerationDialog extends ConsumerStatefulWidget {
  final List<PlannedWorkoutDto> routines;

  const RoutineGenerationDialog({
    super.key,
    required this.routines,
  });

  @override
  ConsumerState<RoutineGenerationDialog> createState() => _RoutineGenerationDialogState();
}

class _RoutineGenerationDialogState extends ConsumerState<RoutineGenerationDialog> {
  /// AI 원본 (불변)
  late List<PlannedWorkoutDto> baseRoutines;
  /// 화면 표시용 (모드별 계산된 targetWeight 반영)
  late List<PlannedWorkoutDto> displayRoutines;
  RoutineIntensity _selectedMode = RoutineIntensity.normal;
  /// 모든 운동 날짜 통일하기 (기본값: false = AI가 제안한 요일별 날짜 유지)
  bool _unifyDate = false;
  /// 통일 모드에서 사용할 날짜
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    baseRoutines = List<PlannedWorkoutDto>.from(widget.routines);
    displayRoutines = baseRoutines.map((e) => e.copyWith()).toList();
    _selectedDate = DateTime.now().add(const Duration(days: 7));
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _applyModeToDisplay();
  }

  void _applyModeToDisplay() {
    // [Phase 4] 유지 모드: 빈 리스트 표시 (실제 데이터는 저장 시 past 7 days에서 가져옴)
    if (_selectedMode == RoutineIntensity.maintain) {
      displayRoutines = [];
      return;
    }
    displayRoutines = baseRoutines.map((base) {
      final tw = base.targetWeight;
      final baseVal = tw;
      double newTarget;
      switch (_selectedMode) {
        case RoutineIntensity.high:
          newTarget = baseVal + 2.5;
          break;
        case RoutineIntensity.normal:
          newTarget = baseVal;
          break;
        case RoutineIntensity.condition:
          final val = (baseVal * 0.85 / 2.5).round() * 2.5;
          newTarget = math.max(0.0, val);
          break;
        case RoutineIntensity.maintain:
          newTarget = baseVal;
          break;
      }
      return base.copyWith(targetWeight: newTarget);
    }).toList();
  }

  void _selectMode(RoutineIntensity mode) {
    setState(() {
      _selectedMode = mode;
      _applyModeToDisplay();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await AdaptiveWidgets.showAdaptiveDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _apply() async {
    // 프리미엄 체크 (Try-then-Buy 모델: 저장 시점에 체크)
    final isPremium = ref.read(subscriptionProvider).isPremium;

    if (!isPremium) {
      // 비프리미엄 사용자: 저장 불가, 구독 유도
      final isPurchased = await showPremiumGuidanceDialog(context);
      if (isPurchased == true && context.mounted) {
        ref.invalidate(subscriptionProvider);
        // 결제 성공 후 사용자가 저장을 다시 시도할 수 있도록 다이얼로그 유지
      }
      return;
    }

    // 프리미엄 사용자: 기존 저장 로직 실행
    final colorHex = _intensityColorHex[_selectedMode]!;
    // [Phase 4] 유지 모드: isMaintainMode 플래그를 true로 설정하여 반환
    // 실제 past 7 days 데이터 fetching은 parent에서 처리
    if (_selectedMode == RoutineIntensity.maintain) {
      Navigator.pop(context, RoutineApplyResult([], colorHex, isMaintainMode: true));
      return;
    }
    if (!_unifyDate) {
      // AI가 제안한 요일별 날짜(scheduledDate)를 그대로 유지
      Navigator.pop(context, RoutineApplyResult(displayRoutines, colorHex));
      return;
    }
    final updatedList =
        displayRoutines.map((dto) => dto.copyWith(scheduledDate: _selectedDate)).toList();
    Navigator.pop(context, RoutineApplyResult(updatedList, colorHex));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(_selectedDate);
    // [Phase 4] rest → maintain 변경
    final isMaintain = _selectedMode == RoutineIntensity.maintain;
    final applyButtonLabel = isMaintain ? '지난주 운동 유지하기' : '운동 계획 저장하기';
    final unifyApplyButtonLabel = DateFormat('M월 d일', 'ko_KR').format(_selectedDate);

    return AlertDialog(
      title: const Text('다음 주 루틴이 준비되었습니다! (AI)'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIntensitySelector(),
            const SizedBox(height: 16),
            // [Phase 4] 유지 모드: "오늘은 휴식입니다" 제거, 설명 메시지로 대체
            if (isMaintain)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 48,
                        color: Colors.purple[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '지난 7일간의 운동을',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        '다음 주에 그대로 반복합니다.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayRoutines.length,
                  itemBuilder: (context, index) {
                    final routine = displayRoutines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(routine.exerciseName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${routine.currentWeight}kg × ${routine.currentReps}회 ➔ ${routine.targetWeight}kg × ${routine.targetReps}회${routine.targetSets > 0 ? ' (${routine.targetSets}세트)' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildCommentBadge(routine.aiComment),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (!isMaintain) _buildDatePicker(dateLabel: dateLabel),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: Text(
            isMaintain
                ? applyButtonLabel
                : (_unifyDate ? '$unifyApplyButtonLabel에 루틴 예약하기' : applyButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({required String dateLabel}) {
    final disabled = !_unifyDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('모든 운동 날짜 통일하기'),
          value: _unifyDate,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _unifyDate = value);
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: disabled,
            child: TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('날짜 변경: $dateLabel'),
            ),
          ),
        ),
        if (disabled)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'AI가 제안한 요일별 날짜를 유지합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildIntensitySelector() {
    return SegmentedButton<RoutineIntensity>(
      segments: const [
        ButtonSegment(
          value: RoutineIntensity.high,
          label: Text('어려움'),
          icon: Icon(Icons.whatshot, size: 18),
        ),
        ButtonSegment(
          value: RoutineIntensity.normal,
          label: Text('보통'),
          icon: Icon(Icons.water_drop, size: 18),
        ),
        ButtonSegment(
          value: RoutineIntensity.condition,
          label: Text('조절'),
          icon: Icon(Icons.air, size: 18),
        ),
        // [Phase 4] 휴식 → 유지 변경
        ButtonSegment(
          value: RoutineIntensity.maintain,
          label: Text('유지'),
          icon: Icon(Icons.repeat, size: 18),
        ),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (Set<RoutineIntensity> selected) {
        _selectMode(selected.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
      ),
    );
  }

  Widget _buildCommentBadge(String comment) {
    Color color;
    if (comment.contains('증량') || comment.contains('도전')) {
      color = Colors.red;
    } else if (comment.contains('횟수')) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        comment,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
