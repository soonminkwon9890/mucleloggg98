import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../core/utils/exercise_category_helper.dart';
import '../../screens/exercise/exercise_add_screen.dart';
import '../../screens/exercise/exercise_input_screen.dart';
import '../../screens/checkpoint/video_upload_screen.dart';
import '../../screens/checkpoint/checkpoint_camera_screen.dart';

/// 홈 화면 (당일 운동 기록 및 운동 찾기)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ExerciseBaseline> _getTodayWorkouts(List<ExerciseBaseline> baselines) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 오늘 날짜의 세트가 있는 운동만 필터링
    final filtered = baselines.where((baseline) {
      if (baseline.workoutSets == null || baseline.workoutSets!.isEmpty) {
        return false;
      }
      return baseline.workoutSets!.any((set) {
        if (set.createdAt == null) return false;
        final setDate =
            '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}-${set.createdAt!.day.toString().padLeft(2, '0')}';
        return setDate == todayStr;
      });
    }).toList();

    // 중복 제거: 같은 baseline_id를 가진 운동은 한 번만 표시
    final seenIds = <String>{};
    return filtered.where((baseline) {
      if (seenIds.contains(baseline.id)) {
        return false;
      }
      seenIds.add(baseline.id);
      return true;
    }).toList();
  }

  /// 오늘의 총 볼륨 계산 (weight * reps 합계)
  double _calculateTodayVolume(List<ExerciseBaseline> todayWorkouts) {
    double totalVolume = 0.0;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (final baseline in todayWorkouts) {
      if (baseline.workoutSets == null) continue;
      for (final set in baseline.workoutSets!) {
        if (set.createdAt == null) continue;
        final setDate =
            '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}-${set.createdAt!.day.toString().padLeft(2, '0')}';
        if (setDate == todayStr) {
          totalVolume += set.weight * set.reps;
        }
      }
    }
    return totalVolume;
  }

  /// 오늘 기록 중 볼륨이 가장 높은 부위와 타입 찾기
  String _getMainFocusArea(List<ExerciseBaseline> todayWorkouts) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 부위별 볼륨 집계
    final Map<String, double> volumeByCategory = {};

    for (final baseline in todayWorkouts) {
      if (baseline.workoutSets == null) continue;
      
      final bodyPartKr = ExerciseCategoryHelper.getKoreanFromBodyPart(
        baseline.bodyPart,
      );
      final movementTypeKr = ExerciseCategoryHelper.getKoreanFromMovementType(
        baseline.movementType,
      );

      for (final set in baseline.workoutSets!) {
        if (set.createdAt == null) continue;
        final setDate =
            '${set.createdAt!.year}-${set.createdAt!.month.toString().padLeft(2, '0')}-${set.createdAt!.day.toString().padLeft(2, '0')}';
        if (setDate == todayStr) {
          final categoryKey = bodyPartKr.isNotEmpty
              ? (movementTypeKr.isNotEmpty ? '$bodyPartKr($movementTypeKr)' : bodyPartKr)
              : '기타';
          volumeByCategory[categoryKey] =
              (volumeByCategory[categoryKey] ?? 0.0) + (set.weight * set.reps);
        }
      }
    }

    if (volumeByCategory.isEmpty) {
      return '기록 없음';
    }

    // 가장 높은 볼륨을 가진 카테고리 찾기
    final maxEntry = volumeByCategory.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return maxEntry.key;
  }

  @override
  Widget build(BuildContext context) {
    final baselinesAsync = ref.watch(baselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 바로 입력 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ExerciseInputScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('운동 기록하기'),
      ),
      body: SafeArea(
        child: authStateAsync.when(
          data: (isAuthenticated) {
            if (!isAuthenticated) {
              return const Center(
                child: Text('로그인이 필요합니다'),
              );
            }

            return baselinesAsync.when(
              data: (baselines) {

                final todayWorkouts = _getTodayWorkouts(baselines);
                final totalVolume = _calculateTodayVolume(todayWorkouts);
                final mainFocus = _getMainFocusArea(todayWorkouts);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 요약 카드
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '오늘 총 볼륨',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${totalVolume.toStringAsFixed(1)}kg',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                '오늘의 집중',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mainFocus,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 오늘의 운동 섹션
                      const Text(
                        '오늘의 운동',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (todayWorkouts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('오늘 기록된 운동이 없습니다'),
                          ),
                        )
                      else
                        ...todayWorkouts.map((baseline) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: baseline.thumbnailUrl != null &&
                                      baseline.thumbnailUrl!.isNotEmpty
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
                                              Icons.fitness_center,
                                              size: 50);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.fitness_center, size: 50),
                              title: Text(baseline.exerciseName),
                              children: [
                                // 세트 정보 리스트 (인덱스 사용)
                                if (baseline.workoutSets != null &&
                                    baseline.workoutSets!.isNotEmpty)
                                  ...baseline.workoutSets!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final set = entry.value;
                                    return ListTile(
                                      title: Text(
                                          '${set.weight}kg × ${set.reps}회'),
                                      subtitle: Text('${index + 1}세트'),
                                    );
                                  }),
                                // 액션 버튼 (영상 유무에 따라 분기)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ExerciseAddScreen(
                                                initialBaseline: baseline,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.replay),
                                        label: const Text('다시하기'),
                                      ),
                                      // 영상이 있으면 중간 점검, 없으면 영상 등록하기
                                      baseline.videoUrl != null &&
                                              baseline.videoUrl!.isNotEmpty
                                          ? OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        CheckpointCameraScreen(
                                                      baseline: baseline,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon:
                                                  const Icon(Icons.camera_alt),
                                              label: const Text('중간 점검'),
                                            )
                                          : ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        VideoUploadScreen(
                                                      baseline: baseline,
                                                      isCheckpoint: false,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                  Icons.video_library),
                                              label: const Text('영상 등록하기'),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
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
      ),
    );
  }
}
