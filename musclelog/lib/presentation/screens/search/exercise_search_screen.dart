import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../workout/workout_analysis_screen.dart';

/// 운동 검색 화면
class ExerciseSearchScreen extends ConsumerStatefulWidget {
  const ExerciseSearchScreen({super.key});

  @override
  ConsumerState<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends ConsumerState<ExerciseSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciseBaseline> _filterBaselines(List<ExerciseBaseline> baselines) {
    if (_searchQuery.isEmpty) return baselines;
    return baselines.where((baseline) {
      return baseline.exerciseName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(baselinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 찾기'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '운동 이름으로 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: baselinesAsync.when(
              data: (baselines) {
                final filtered = _filterBaselines(baselines);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('검색 결과가 없습니다'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final baseline = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(baseline.exerciseName),
                        subtitle: Text('${baseline.bodyPart ?? ''} • ${baseline.targetMuscle ?? ''}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutAnalysisScreen(
                                baseline: baseline,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

