import 'package:flutter/material.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../core/enums/exercise_enums.dart';

/// Universal Drag-and-Drop Reorder Dialog
///
/// Displays a modal dialog that allows users to reorder a list of exercises
/// using drag-and-drop. Similar to native app experiences (e.g., Selfit).
///
/// [currentList]: The current list of exercises to reorder
/// [onReorderCompleted]: Callback when the dialog is dismissed with the new order
Future<void> showReorderWorkoutDialog(
  BuildContext context,
  List<ExerciseBaseline> currentList,
  Function(List<ExerciseBaseline>) onReorderCompleted,
) async {
  // Create a mutable copy of the list
  final reorderedList = List<ExerciseBaseline>.from(currentList);

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.swap_vert, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '순서 변경',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onReorderCompleted(reorderedList);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '항목을 길게 눌러 드래그하세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: reorderedList.length,
                      onReorder: (oldIndex, newIndex) {
                        setDialogState(() {
                          // ReorderableListView returns newIndex as if the item
                          // at oldIndex is already removed, so adjust accordingly
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = reorderedList.removeAt(oldIndex);
                          reorderedList.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final baseline = reorderedList[index];
                        final targetMusclesText = baseline.targetMuscles != null &&
                                baseline.targetMuscles!.isNotEmpty
                            ? baseline.targetMuscles!.join(', ')
                            : baseline.bodyPart?.label ?? '미분류';

                        return Card(
                          key: ValueKey('reorder_${baseline.id}'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          elevation: 1,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 12,
                              right: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            title: Text(
                              baseline.exerciseName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              targetMusclesText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // Return original list (cancel)
                  onReorderCompleted(currentList);
                },
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onReorderCompleted(reorderedList);
                },
                child: const Text('적용'),
              ),
            ],
          );
        },
      );
    },
  );
}
