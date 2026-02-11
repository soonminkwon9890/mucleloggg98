import 'package:flutter/material.dart';

/// 운동 완료 다이얼로그
/// 운동 저장 시 강도(difficulty)를 선택하는 다이얼로그
class WorkoutFinishDialog extends StatefulWidget {
  final double totalVolume;
  final int? durationMinutes; // 선택적

  const WorkoutFinishDialog({
    super.key,
    required this.totalVolume,
    this.durationMinutes,
  });

  @override
  State<WorkoutFinishDialog> createState() => _WorkoutFinishDialogState();
}

class _WorkoutFinishDialogState extends State<WorkoutFinishDialog> {
  String _selectedDifficulty = 'normal'; // 기본값: 보통

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 완료'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 정보
          Text(
            '총 볼륨: ${widget.totalVolume.toStringAsFixed(1)}kg',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // 강도 선택 안내
          const Text(
            '오늘 운동의 강도는 어땠나요?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // 강도 선택 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton('easy', '쉬움', Icons.sentiment_very_satisfied),
              _buildDifficultyButton('normal', '보통', Icons.sentiment_neutral),
              _buildDifficultyButton('hard', '어려움', Icons.sentiment_very_dissatisfied),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), // 취소
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedDifficulty),
          child: const Text('기록 저장하기'),
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(String difficulty, String label, IconData icon) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

