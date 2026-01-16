import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ExerciseBaseline>? _selectedDayWorkouts;
  bool _isLoadingWorkouts = false;
  
  // 검색 패널 상태
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
      final history = await repository.getWorkoutHistoryByExercise(exerciseName);
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

  Future<void> _loadWorkoutsForDate(DateTime date) async {
    setState(() {
      _isLoadingWorkouts = true;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final workouts = await repository.getWorkoutsByDate(date);
      if (mounted) {
        setState(() {
          _selectedDayWorkouts = workouts;
          _isLoadingWorkouts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedDayWorkouts = [];
          _isLoadingWorkouts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final workoutDatesAsync = ref.watch(workoutDatesProvider);
    final baselinesAsync = ref.watch(baselinesProvider);
    final isSearchOpen = ref.watch(isProfileSearchOpenProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.5;

    return SafeArea(
      child: profileAsync.when(
        data: (profile) {
          return Stack(
            children: [
              // Layer 1: 기존 캘린더 및 운동 리스트
              SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 달력 섹션 (운동 기록 날짜 하이라이트)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '운동 기록 달력',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        workoutDatesAsync.when(
                          data: (workoutDates) {
                            return TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  _selectedDay != null &&
                                  isSameDay(_selectedDay!, day),
                              locale: 'ko_KR',
                              calendarFormat: CalendarFormat.month,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              eventLoader: (day) {
                                // workoutDates에서 해당 날짜와 같은 날짜 찾기
                                return workoutDates
                                    .where((date) => isSameDay(date, day))
                                    .toList();
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                                _loadWorkoutsForDate(selectedDay);
                              },
                              onPageChanged: (focusedDay) {
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => SizedBox(
                            height: 300,
                            child: Center(
                              child: Text('오류: $error'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 선택된 날짜의 운동 리스트
                if (_selectedDay == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '날짜를 선택하세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_isLoadingWorkouts)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_selectedDayWorkouts == null)
                  const SizedBox.shrink()
                else if (_selectedDayWorkouts!.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '선택한 날짜에 운동 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일 운동',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._selectedDayWorkouts!.map((baseline) {
                          return ListTile(
                            leading: baseline.thumbnailUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      baseline.thumbnailUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                            Icons.fitness_center, size: 40);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.fitness_center, size: 40),
                            title: Text(baseline.exerciseName),
                            subtitle: baseline.workoutSets != null &&
                                    baseline.workoutSets!.isNotEmpty
                                ? Text(
                                    '${baseline.workoutSets!.length}세트',
                                  )
                                : null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // 운동 분석 화면으로 이동 (필요 시 구현)
                            },
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
              ),
              // Layer 2: 검색 패널 (AnimatedPositioned)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: isSearchOpen ? 0 : -panelHeight,
                left: 0,
                right: 0,
                height: panelHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 드래그 핸들
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // 검색 입력 필드
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '운동 이름으로 검색',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                ref.read(isProfileSearchOpenProvider.notifier).state = false;
                                setState(() {
                                  _searchQuery = '';
                                  _selectedExerciseName = null;
                                  _workoutHistory = null;
                                  _searchController.clear();
                                });
                              },
                            ),
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
                            ? baselinesAsync.when(
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
                              onPressed: () {
                                ref.read(isProfileSearchOpenProvider.notifier).state = false;
                                setState(() {
                                  _searchQuery = '';
                                  _selectedExerciseName = null;
                                  _workoutHistory = null;
                                  _searchController.clear();
                                });
                              },
                              child: const Text('닫기'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류: $error'),
        ),
      ),
    );
  }
}

