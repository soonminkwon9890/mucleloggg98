import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/planned_workout.dart';
import '../../providers/workout_provider.dart';

class EditPlannedWorkoutDialog extends ConsumerStatefulWidget {
  final PlannedWorkout plannedWorkout;
  final String exerciseName;
  final VoidCallback onUpdated;

  const EditPlannedWorkoutDialog({
    super.key,
    required this.plannedWorkout,
    required this.exerciseName,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditPlannedWorkoutDialog> createState() => _EditPlannedWorkoutDialogState();
}

class _EditPlannedWorkoutDialogState extends ConsumerState<EditPlannedWorkoutDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late String _selectedColorHex;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.plannedWorkout.targetWeight.toString());
    _repsController = TextEditingController(text: widget.plannedWorkout.targetReps.toString());
    _selectedColorHex = widget.plannedWorkout.colorHex;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 무게를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 횟수를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.updatePlannedWorkout(
        widget.plannedWorkout.id,
        targetWeight: weight,
        targetReps: reps,
        colorHex: _selectedColorHex,
        aiComment: widget.plannedWorkout.aiComment, // 기존 코멘트 유지
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계획이 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.exerciseName} 수정'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '목표 무게 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '무게를 입력해주세요.';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return '올바른 무게를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: '목표 횟수',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '횟수를 입력해주세요.';
                  }
                  final reps = int.tryParse(value);
                  if (reps == null || reps <= 0) {
                    return '올바른 횟수를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('캘린더에 표시할 색상 선택:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildColorChip('0xFFF44336', Colors.red, '강도 높음'),
                  _buildColorChip('0xFF2196F3', Colors.blue, '보통'),
                  _buildColorChip('0xFFFFEB3B', Colors.yellow, '컨디션 조절'),
                  _buildColorChip('0xFF9E9E9E', Colors.grey, '휴식'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => _saveChanges(context),
          child: const Text('수정'),
        ),
      ],
    );
  }

  Widget _buildColorChip(String colorHex, Color color, String label) {
    final isSelected = _selectedColorHex == colorHex;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedColorHex = colorHex;
          });
        }
      },
      selectedColor: color.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

