import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// RPE 선택 위젯
class RPESelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RPESelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 자각도 (RPE): $value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: AppConstants.rpeMin.toDouble(),
          max: AppConstants.rpeMax.toDouble(),
          divisions: 9,
          label: value.toString(),
          onChanged: (newValue) => onChanged(newValue.toInt()),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppConstants.rpeMin} (매우 쉬움)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${AppConstants.rpeMax} (최대 강도)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRpeColor(value).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getRpeColor(value)),
          ),
          child: Row(
            children: [
              Icon(_getRpeIcon(value), color: _getRpeColor(value)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getRpeDescription(value),
                  style: TextStyle(
                    color: _getRpeColor(value),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRpeColor(int rpe) {
    if (rpe < 5) {
      return Colors.green;
    } else if (rpe < 8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getRpeIcon(int rpe) {
    if (rpe < 5) {
      return Icons.sentiment_very_satisfied;
    } else if (rpe < 8) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.sentiment_very_dissatisfied;
    }
  }

  String _getRpeDescription(int rpe) {
    if (rpe < 5) {
      return '웜업 수준. 여유롭게 수행 가능';
    } else if (rpe < 8) {
      return '자극 위주. 3회 이상 더 할 수 있음';
    } else {
      return '실패지점 근접. 매우 어려움';
    }
  }
}
