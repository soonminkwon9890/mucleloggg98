import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/adaptive_widgets.dart';
import '../../../data/models/planned_workout.dart';
import '../../providers/workout_provider.dart';

/// 캘린더 화면의 계획된 운동 타일
/// 3-dots 메뉴 버튼으로 "날짜 수정", "삭제" 옵션 제공
class PlannedWorkoutTile extends ConsumerWidget {
  final PlannedWorkout plannedWorkout;
  final String exerciseName;
  final VoidCallback onUpdated;

  const PlannedWorkoutTile({
    super.key,
    required this.plannedWorkout,
    required this.exerciseName,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: ValueKey('planned_${plannedWorkout.id}'),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(int.parse(plannedWorkout.colorHex)).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.fitness_center,
          color: Color(int.parse(plannedWorkout.colorHex)),
          size: 20,
        ),
      ),
      title: Text(
        exerciseName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Manual(0kg x 0회) vs AI Plan(값 있음) 구분 표시
          Text(
            plannedWorkout.targetWeight == 0 && plannedWorkout.targetReps == 0
                ? '${plannedWorkout.targetSets}세트 예정'
                : '${plannedWorkout.targetWeight}kg × ${plannedWorkout.targetReps}회 (${plannedWorkout.targetSets}세트)',
          ),
          if (plannedWorkout.aiComment != null && plannedWorkout.aiComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCommentBadge(plannedWorkout.aiComment!),
          ],
        ],
      ),
      // 3-dots 메뉴 버튼
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showOptionsSheet(context, ref),
      ),
    );
  }

  /// 옵션 BottomSheet 표시 (3-dots 메뉴)
  void _showOptionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 운동 이름 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // 날짜 수정
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('날짜 수정'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changeDate(context, ref);
                },
              ),
              // 삭제
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// [Task 1] 날짜 수정 - DatePicker 표시 후 DB 업데이트
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

    final picked = await AdaptiveWidgets.showAdaptiveDatePicker(
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

  /// [Task 1] 삭제 확인 다이얼로그 표시 후 DB 삭제
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계획 삭제'),
        content: Text('$exerciseName 계획을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.deletePlannedWorkout(plannedWorkout.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계획이 삭제되었습니다.'),
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
