import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../core/utils/exercise_category_helper.dart';
import 'workout_analysis_screen.dart';

/// 운동 기록 화면 (필터링 가능한 전체 기록 조회)
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedBodyPart; // '상체', '하체', '전신'
  String? _selectedMovementType; // '전체', '밀기', '당기기' - 상체 선택 시에만 활성화
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          final tabs = ['상체', '하체', '전신'];
          _selectedBodyPart = tabs[_tabController.index];
          // 탭 변경 시 movementType 초기화
          _selectedMovementType = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ExerciseBaseline> _filterBaselines(List<ExerciseBaseline> baselines) {
    if (_selectedBodyPart == null) return baselines;

    // 한글을 영문으로 변환
    final bodyPartEn =
        ExerciseCategoryHelper.getBodyPartFromKorean(_selectedBodyPart!);

    // bodyPart 기준 필터링
    var filtered = baselines.where((baseline) {
      return baseline.bodyPart == bodyPartEn;
    }).toList();

    // 상체 선택 시 movementType 추가 필터링
    if (_selectedBodyPart == '상체' &&
        _selectedMovementType != null &&
        _selectedMovementType != '전체') {
      final movementTypeEn = ExerciseCategoryHelper.getMovementTypeFromKorean(
        _selectedMovementType!,
      );
      filtered = filtered.where((baseline) {
        return baseline.movementType == movementTypeEn;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(baselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return SafeArea(
      child: authStateAsync.when(
        data: (isAuthenticated) {
          if (!isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다'),
            );
          }

          return baselinesAsync.when(
            data: (baselines) {
              final filteredBaselines = _filterBaselines(baselines);

              return Column(
                children: [
                  // 상단 필터 탭바
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '상체'),
                      Tab(text: '하체'),
                      Tab(text: '전신'),
                    ],
                    onTap: (index) {
                      setState(() {
                        final tabs = ['상체', '하체', '전신'];
                        _selectedBodyPart = tabs[index];
                        _selectedMovementType = null;
                      });
                    },
                  ),

                  // 상체 선택 시 서브 필터 칩
                  if (_selectedBodyPart == '상체')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: ['전체', '밀기', '당기기'].map((type) {
                          return FilterChip(
                            label: Text(type),
                            selected: _selectedMovementType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedMovementType = selected ? type : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  // 리스트
                  Expanded(
                    child: filteredBaselines.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  '기록된 운동이 없습니다',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredBaselines.length,
                            itemBuilder: (context, index) {
                              final baseline = filteredBaselines[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  leading: baseline.thumbnailUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            baseline.thumbnailUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.fitness_center,
                                                  size: 40);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.fitness_center,
                                          size: 40),
                                  title: Text(baseline.exerciseName),
                                  subtitle: Text(
                                    baseline.feedbackPrompt ?? '분석 결과 없음',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('오류: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('인증 오류: $error'),
        ),
      ),
    );
  }
}
