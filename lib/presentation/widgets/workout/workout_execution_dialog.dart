import 'package:flutter/material.dart';

import '../../../data/models/planned_workout.dart';
import '../../../data/models/workout_completion_input.dart';

class WorkoutExecutionDialog extends StatefulWidget {
  final List<PlannedWorkout> plans;
  final Map<String, String> exerciseNames; // baselineId -> exerciseName

  const WorkoutExecutionDialog({
    super.key,
    required this.plans,
    required this.exerciseNames,
  });

  @override
  State<WorkoutExecutionDialog> createState() => _WorkoutExecutionDialogState();
}

class _WorkoutExecutionDialogState extends State<WorkoutExecutionDialog> {
  late final List<TextEditingController> _weightControllers;
  late final List<TextEditingController> _repsControllers;

  @override
  void initState() {
    super.initState();
    _weightControllers = widget.plans
        .map((p) => TextEditingController(text: p.targetWeight.toString()))
        .toList();
    _repsControllers = widget.plans
        .map((p) => TextEditingController(text: p.targetReps.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final inputs = <WorkoutCompletionInput>[];
    for (int i = 0; i < widget.plans.length; i++) {
      final plan = widget.plans[i];
      final weightText = _weightControllers[i].text.trim().replaceAll(',', '.');
      final repsText = _repsControllers[i].text.trim();

      final weight = double.tryParse(weightText) ?? 0.0;
      final reps = int.tryParse(repsText) ?? 0;

      inputs.add(
        WorkoutCompletionInput(
          plannedWorkoutId: plan.id,
          actualWeight: weight,
          actualReps: reps,
          actualSets: plan.targetSets,
        ),
      );
    }

    Navigator.pop(context, inputs);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 결과 확정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.plans.length, (index) {
            final plan = widget.plans[index];
            final name = widget.exerciseNames[plan.baselineId] ??
                plan.exerciseName ??
                'Unknown';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Weight',
                            suffixText: 'kg',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _repsControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            suffixText: '회',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('확인'),
        ),
      ],
    );
  }
}

