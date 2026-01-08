import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'workout_log_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';

/// 메인 화면 (3단 탭 구조)
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutLogScreen(),
    const ProfileScreen(),
  ];

  final List<String> _appBarTitles = [
    'MuscleLog',
    '운동 기록',
    '내 프로필',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex]),
        leading: _currentIndex == 2
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final baselinesAsync = ref.read(baselinesProvider);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => _ExerciseSearchModal(
                      baselinesAsync: baselinesAsync,
                    ),
                  );
                },
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

/// 운동 검색 모달
class _ExerciseSearchModal extends ConsumerStatefulWidget {
  final AsyncValue<List<ExerciseBaseline>> baselinesAsync;

  const _ExerciseSearchModal({
    required this.baselinesAsync,
  });

  @override
  ConsumerState<_ExerciseSearchModal> createState() =>
      _ExerciseSearchModalState();
}

class _ExerciseSearchModalState extends ConsumerState<_ExerciseSearchModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedExerciseName;
  Map<String, List<WorkoutSet>>? _workoutHistory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciseBaseline> _filterBaselines(List<ExerciseBaseline> baselines) {
    if (_searchQuery.isEmpty) return baselines;
    return baselines
        .where((baseline) => baseline.exerciseName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _loadWorkoutHistory(String exerciseName) async {
    setState(() {
      _selectedExerciseName = exerciseName;
      _workoutHistory = null;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final history =
          await repository.getWorkoutHistoryByExercise(exerciseName);
      if (mounted) {
        setState(() {
          _workoutHistory = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workoutHistory = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 검색 입력 필드
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

            // 검색 결과 또는 월별 기록
            Expanded(
              child: _selectedExerciseName == null
                  ? widget.baselinesAsync.when(
                      data: (baselines) {
                        final filtered = _filterBaselines(baselines);
                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text('검색 결과가 없습니다'),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final baseline = filtered[index];
                            return ListTile(
                              title: Text(baseline.exerciseName),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                _loadWorkoutHistory(baseline.exerciseName);
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('오류: $error'),
                      ),
                    )
                  : _workoutHistory == null
                      ? const Center(child: CircularProgressIndicator())
                      : _workoutHistory!.isEmpty
                          ? const Center(
                              child: Text('기록이 없습니다'),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _workoutHistory!.length,
                              itemBuilder: (context, index) {
                                final monthKey =
                                    _workoutHistory!.keys.toList()[index];
                                final sets = _workoutHistory![monthKey]!;
                                return ExpansionTile(
                                  title: Text(monthKey),
                                  subtitle: Text('${sets.length}세트'),
                                  children: sets.map((set) {
                                    return ListTile(
                                      title: Text(
                                          '${set.weight}kg × ${set.reps}회'),
                                      subtitle: set.createdAt != null
                                          ? Text(
                                              '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}-${set.createdAt!.day.toString().padLeft(2, '0')}')
                                          : null,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_selectedExerciseName != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedExerciseName = null;
                          _workoutHistory = null;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('뒤로'),
                    )
                  else
                    const SizedBox.shrink(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

