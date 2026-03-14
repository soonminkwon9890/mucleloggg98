import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
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

    // [Phase 1] 동적 키보드 패딩(viewInsets.bottom) 완전 제거
    // 고정 높이 85%로 시트가 충분히 크므로 키보드가 올라와도 검색바가 보임
    // [Phase 2] 외부 탭 시 키보드 닫기 (translucent로 빈 공간도 감지)
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        top: false,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16,
            ),
            child: Column(
              children: [
                // 드래그 핸들
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
                // 검색 입력 필드
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
                // 검색 결과 리스트
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('검색 결과가 없습니다'))
                      : ListView.builder(
                          controller: widget.scrollController,
                          primary: widget.scrollController == null,
                          // [Phase 2] 스크롤 시 키보드 자동 닫기
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ExpansionTile(
                              title: Text(item.exerciseName),
                              // [Phase 2] 확장 시 키보드 닫기
                              onExpansionChanged: (_) =>
                                  FocusScope.of(context).unfocus(),
                              children: item.performedDates.map((d) {
                                final label =
                                    DateFormatter.formatDateWithWeekday(d);
                                return ListTile(
                                  title: Text(label),
                                  onTap: () {
                                    // [Phase 2] 결과 탭 시 키보드 먼저 닫기
                                    FocusScope.of(context).unfocus();
                                    widget.onDateSelected(d);
                                  },
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
      ),
    );
  }
}


