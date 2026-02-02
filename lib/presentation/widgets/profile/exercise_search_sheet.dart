import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/exercise_with_history.dart';

class ExerciseSearchSheet extends StatefulWidget {
  final List<ExerciseWithHistory> items;
  final void Function(DateTime date) onDateSelected;
  final ScrollController? scrollController;

  const ExerciseSearchSheet({
    super.key,
    required this.items,
    required this.onDateSelected,
    this.scrollController,
  });

  @override
  State<ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<ExerciseSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.items
        : widget.items
            .where((e) =>
                e.exerciseName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + bottomInset,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '운동 이름으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _query = '';
                            });
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다'))
                    : ListView.builder(
                        controller: widget.scrollController,
                        primary: widget.scrollController == null,
                        physics: widget.scrollController != null
                            ? const ClampingScrollPhysics()
                            : null,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ExpansionTile(
                            title: Text(item.exerciseName),
                            children: item.performedDates.map((d) {
                              final label = DateFormat('yyyy-MM-dd (E)', 'ko_KR')
                                  .format(d);
                              return ListTile(
                                title: Text(label),
                                onTap: () => widget.onDateSelected(d),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

