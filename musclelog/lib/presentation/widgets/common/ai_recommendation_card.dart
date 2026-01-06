import 'package:flutter/material.dart';
import '../../../data/models/workout_set.dart';

/// AI 추천 카드 위젯
class AIRecommendationCard extends StatelessWidget {
  final WorkoutSet recommendation;
  final VoidCallback onAccept;

  const AIRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'AI 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '오늘은 ${recommendation.weight}kg으로 ${recommendation.reps}회를 시도해보세요!',
              style: const TextStyle(fontSize: 14),
            ),
            if (recommendation.estimated1rm != null) ...[
              const SizedBox(height: 8),
              Text(
                '추정 1RM: ${recommendation.estimated1rm!.toStringAsFixed(1)}kg',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check),
                label: const Text('추천 수락'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
