import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/planned_workout.dart';
import '../../providers/workout_provider.dart';
import 'edit_planned_workout_dialog.dart';

class PlannedWorkoutTile extends ConsumerWidget {
  final PlannedWorkout plannedWorkout;
  final String exerciseName;
  final VoidCallback onUpdated; // 갱신 콜백

  const PlannedWorkoutTile({
    super.key,
    required this.plannedWorkout,
    required this.exerciseName,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Checkbox(
        value: plannedWorkout.isCompleted,
        onChanged: (checked) => _toggleCompletion(context, ref, checked ?? false),
      ),
      title: Text(
        exerciseName,
        style: plannedWorkout.isCompleted
            ? const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              )
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${plannedWorkout.targetWeight}kg × ${plannedWorkout.targetReps}회'),
          if (plannedWorkout.aiComment != null && plannedWorkout.aiComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCommentBadge(plannedWorkout.aiComment!),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'date',
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18),
                SizedBox(width: 8),
                Text('날짜 변경'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Text('수정'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('삭제'),
          ),
        ],
        onSelected: (value) {
          if (value == 'date') {
            _changeDate(context, ref);
          } else if (value == 'edit') {
            _showEditDialog(context, ref);
          } else if (value == 'delete') {
            _showDeleteDialog(context, ref);
          }
        },
      ),
    );
  }

  Future<void> _changeDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(const Duration(days: 365));

    final current = DateTime(
      plannedWorkout.scheduledDate.year,
      plannedWorkout.scheduledDate.month,
      plannedWorkout.scheduledDate.day,
    );
    final initialDate = current.isBefore(today) ? today : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked == null) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.updatePlannedWorkoutDate(plannedWorkout.id, picked);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('날짜가 변경되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        onUpdated();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('날짜 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCompletion(BuildContext context, WidgetRef ref, bool isCompleted) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.togglePlannedWorkoutCompletion(plannedWorkout.id, isCompleted);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompleted ? '완료 처리되었습니다.' : '완료 취소되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        onUpdated(); // 갱신 콜백 호출
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EditPlannedWorkoutDialog(
        plannedWorkout: plannedWorkout,
        exerciseName: exerciseName,
        onUpdated: onUpdated,
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계획 삭제'),
        content: const Text('이 계획을 삭제하시겠습니까?'),
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

    if (confirm != true || !context.mounted) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.deletePlannedWorkout(plannedWorkout.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계획이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        onUpdated(); // 갱신 콜백 호출
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

