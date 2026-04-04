import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/exercise_enums.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../providers/workout_provider.dart';
import 'workout_analysis_screen.dart';

// ─── Result type returned by ExerciseSearchDelegate ─────────────────────────

/// Tapping an exercise row's title → openAnalysis = true → open WorkoutAnalysisScreen.
/// Tapping the "최근: M월 d일 →" label → openAnalysis = false, latestDate set → sync Home calendar.
class ExerciseSearchResult {
  final String exerciseName;
  final DateTime? latestDate;
  final bool openAnalysis;

  const ExerciseSearchResult({
    required this.exerciseName,
    this.latestDate,
    required this.openAnalysis,
  });
}

// ─── SearchDelegate ──────────────────────────────────────────────────────────

/// Wraps the exercise-search UX as a Flutter [SearchDelegate] so it can be
/// launched with [showSearch] instead of a heavy [Navigator.push].
///
/// Pass a (possibly empty) pre-fetched [baselines] list; when the list is empty
/// the delegate shows a loading/error fallback in the caller.
class ExerciseSearchDelegate extends SearchDelegate<ExerciseSearchResult?> {
  final List<ExerciseBaseline> baselines;

  ExerciseSearchDelegate({required this.baselines})
      : super(searchFieldLabel: '운동 이름으로 검색');

  // ── helpers ──────────────────────────────────────────────────────────────

  List<String> _uniqueNames() {
    final seen = <String>{};
    for (final b in baselines) {
      if (b.workoutSets == null || b.workoutSets!.isEmpty) continue;
      if (b.workoutSets!.any((s) => s.isCompleted)) seen.add(b.exerciseName);
    }
    return seen.toList()..sort();
  }

  DateTime? _latestDateFor(String name) {
    DateTime? latest;
    for (final b in baselines.where((b) => b.exerciseName == name)) {
      final completedSets =
          b.workoutSets?.where((s) => s.isCompleted == true) ?? [];
      for (final s in completedSets) {
        final d = s.createdAt;
        if (d != null && (latest == null || d.isAfter(latest))) latest = d;
      }
    }
    return latest;
  }

  // ── SearchDelegate overrides ──────────────────────────────────────────────

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: '지우기',
            onPressed: () {
              query = '';
              showSuggestions(context);
            },
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => BackButton(
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력하세요',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '운동 이름으로 지난 기록을 찾을 수 있습니다',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }
    return _buildList(context);
  }

  // ── list builder ──────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context) {
    final filtered = _uniqueNames()
        .where((n) => n.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '"$query" 검색 결과가 없습니다',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (ctx, i) {
        final name = filtered[i];
        final baseline = baselines.firstWhere((b) => b.exerciseName == name);
        final latestDate = _latestDateFor(name);
        final normalizedDate = latestDate == null
            ? null
            : DateTime(latestDate.year, latestDate.month, latestDate.day);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(ctx).colorScheme.primaryContainer,
            child: Icon(
              Icons.fitness_center,
              size: 20,
              color: Theme.of(ctx).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (baseline.bodyPart != null) Text(baseline.bodyPart!.label),
              if (normalizedDate != null)
                GestureDetector(
                  onTap: () => close(
                    ctx,
                    ExerciseSearchResult(
                      exerciseName: name,
                      latestDate: normalizedDate,
                      openAnalysis: false,
                    ),
                  ),
                  child: Text(
                    '최근: ${normalizedDate.month}월 ${normalizedDate.day}일 →',
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          isThreeLine: baseline.bodyPart != null && normalizedDate != null,
          trailing: const Icon(Icons.chevron_right, size: 20),
          // 항목 탭 → 홈 캘린더 날짜 동기화 (최근 기록일로 이동)
          onTap: () => close(
            ctx,
            ExerciseSearchResult(
              exerciseName: name,
              latestDate: normalizedDate,
              openAnalysis: false,
            ),
          ),
        );
      },
    );
  }
}

// ─── Legacy full-screen widget (kept for any remaining deep-links) ───────────

/// 운동 검색 화면 (standalone).
///
/// 홈 화면에서는 [ExerciseSearchDelegate] + [showSearch] 를 사용합니다.
class ExerciseSearchScreen extends ConsumerStatefulWidget {
  const ExerciseSearchScreen({super.key});

  @override
  ConsumerState<ExerciseSearchScreen> createState() =>
      _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends ConsumerState<ExerciseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _uniqueNames(List<ExerciseBaseline> baselines) {
    final seen = <String>{};
    for (final b in baselines) {
      if (b.workoutSets == null || b.workoutSets!.isEmpty) continue;
      if (b.workoutSets!.any((s) => s.isCompleted)) seen.add(b.exerciseName);
    }
    return seen.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(archivedBaselinesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '운동 이름으로 검색',
            border: InputBorder.none,
            hintStyle:
                TextStyle(color: Theme.of(context).hintColor, fontSize: 17),
          ),
          style: const TextStyle(fontSize: 17),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '지우기',
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('검색어를 입력하세요',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('운동 이름으로 지난 기록을 찾을 수 있습니다',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )
          : baselinesAsync.when(
              data: (baselines) {
                final filtered = _uniqueNames(baselines)
                    .where((name) =>
                        name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('"$_query" 검색 결과가 없습니다',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final name = filtered[i];
                    final baseline =
                        baselines.firstWhere((b) => b.exerciseName == name);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.fitness_center,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: baseline.bodyPart != null
                          ? Text(baseline.bodyPart!.label)
                          : null,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutAnalysisScreen(exerciseName: name),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
            ),
    );
  }
}
