import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/planned_workout_dto.dart';

/// 강도 모드: High(+2.5kg), Normal(원본), Condition(85%), Rest(휴식)
enum RoutineIntensity { high, normal, condition, rest }

/// 모드별 색상 (0xFFRRGGBB, 앱 기존 형식)
const Map<RoutineIntensity, String> _intensityColorHex = {
  RoutineIntensity.high: '0xFFF44336',
  RoutineIntensity.normal: '0xFF2196F3',
  RoutineIntensity.condition: '0xFF4CAF50',
  RoutineIntensity.rest: '0xFF9E9E9E',
};

/// 다이얼로그 적용 결과 (날짜가 주입된 루틴 + 선택 색상)
class RoutineApplyResult {
  final List<PlannedWorkoutDto> routines;
  final String colorHex;
  RoutineApplyResult(this.routines, this.colorHex);
}

class RoutineGenerationDialog extends StatefulWidget {
  final List<PlannedWorkoutDto> routines;

  const RoutineGenerationDialog({
    super.key,
    required this.routines,
  });

  @override
  State<RoutineGenerationDialog> createState() => _RoutineGenerationDialogState();
}

class _RoutineGenerationDialogState extends State<RoutineGenerationDialog> {
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
    if (_selectedMode == RoutineIntensity.rest) {
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
        case RoutineIntensity.rest:
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
    final picked = await showDatePicker(
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

  void _apply() {
    final colorHex = _intensityColorHex[_selectedMode]!;
    if (_selectedMode == RoutineIntensity.rest) {
      Navigator.pop(context, RoutineApplyResult([], colorHex));
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
    final isRest = _selectedMode == RoutineIntensity.rest;
    final applyButtonLabel = isRest ? '오늘은 저장 없이 쉬기' : '운동 계획 저장하기';
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
            if (isRest)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('오늘은 휴식입니다.'),
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
            if (!isRest) _buildDatePicker(dateLabel: dateLabel),
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
            isRest
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
        ButtonSegment(
          value: RoutineIntensity.rest,
          label: Text('휴식'),
          icon: Icon(Icons.hotel, size: 18),
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
