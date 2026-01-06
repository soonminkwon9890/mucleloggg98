import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../providers/workout_provider.dart';
import '../../screens/workout/workout_log_screen.dart';
import '../../screens/checkpoint/checkpoint_camera_screen.dart';

/// 아코디언 형식의 기록 리스트 위젯
class AccordionList extends ConsumerStatefulWidget {
  final ExerciseBaseline baseline;

  const AccordionList({
    super.key,
    required this.baseline,
  });

  @override
  ConsumerState<AccordionList> createState() => _AccordionListState();
}

class _AccordionListState extends ConsumerState<AccordionList> {
  @override
  Widget build(BuildContext context) {
    final workoutSetsAsync = ref.watch(workoutSetsProvider(widget.baseline.id));

    return ExpansionTile(
      leading: widget.baseline.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.baseline.thumbnailUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.fitness_center, size: 40);
                },
              ),
            )
          : const Icon(Icons.fitness_center, size: 40),
      title: Text(
        widget.baseline.exerciseName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${widget.baseline.bodyPart ?? ''} • ${widget.baseline.movementType ?? ''}',
        style: const TextStyle(fontSize: 12),
      ),
      onExpansionChanged: (expanded) {
        // 확장 상태 변경 처리 (필요시 사용)
      },
      children: [
        workoutSetsAsync.when(
          data: (sets) {
            if (sets.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '아직 기록이 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // 날짜별로 그룹핑
            final groupedSets = <String, List<dynamic>>{};
            for (final set in sets) {
              if (set.createdAt != null) {
                final dateKey = DateFormatter.getDateGroupKey(set.createdAt!);
                groupedSets.putIfAbsent(dateKey, () => []).add(set);
              }
            }

            final sortedDates = groupedSets.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              children: sortedDates.map((dateKey) {
                final dateSets = groupedSets[dateKey]!;
                final date = DateTime.parse(dateKey);

                return ExpansionTile(
                  title: Text(
                    DateFormatter.formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${dateSets.length}개 세트'),
                  children: dateSets.map((set) {
                    return ListTile(
                      title: Text('${set.weight}kg × ${set.reps}회'),
                      subtitle: Text(
                        'RPE: ${set.rpe ?? 'N/A'} • 1RM: ${set.estimated1rm?.toStringAsFixed(1) ?? 'N/A'}kg',
                      ),
                      trailing: set.isAiSuggested
                          ? const Icon(Icons.auto_awesome,
                              size: 16, color: Colors.blue)
                          : null,
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('오류: $error'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutLogScreen(baseline: widget.baseline),
                    ),
                  );
                },
                icon: const Icon(Icons.replay),
                label: const Text('다시하기'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckpointCameraScreen(baseline: widget.baseline),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('중간 점검'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
