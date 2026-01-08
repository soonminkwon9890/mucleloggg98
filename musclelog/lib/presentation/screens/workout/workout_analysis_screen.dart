import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../screens/exercise/exercise_add_screen.dart';
import '../../screens/checkpoint/video_upload_screen.dart';
import '../../screens/checkpoint/checkpoint_camera_screen.dart';

/// 운동 분석 화면
class WorkoutAnalysisScreen extends ConsumerStatefulWidget {
  final ExerciseBaseline baseline;

  const WorkoutAnalysisScreen({
    super.key,
    required this.baseline,
  });

  @override
  ConsumerState<WorkoutAnalysisScreen> createState() =>
      _WorkoutAnalysisScreenState();
}

class _WorkoutAnalysisScreenState extends ConsumerState<WorkoutAnalysisScreen> {
  // State 관리: widget.baseline 대신 _currentBaseline 사용
  late ExerciseBaseline _currentBaseline;

  @override
  void initState() {
    super.initState();
    // initState에서 초기화
    _currentBaseline = widget.baseline;
  }

  double _calculateTotalVolume() {
    if (_currentBaseline.workoutSets == null ||
        _currentBaseline.workoutSets!.isEmpty) {
      return 0.0;
    }
    // 총 볼륨 계산: Sum(weight * reps) - sets를 곱하지 않음
    return _currentBaseline.workoutSets!.fold(0.0, (sum, set) {
      return sum + (set.weight * set.reps);
    });
  }

  void _showIntensityFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 강도 피드백'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _handleIntensityFeedback('어려움'),
              child: const Text('어려움'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _handleIntensityFeedback('보통'),
              child: const Text('보통'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _handleIntensityFeedback('낮음'),
              child: const Text('낮음'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleIntensityFeedback(String intensity) {
    Navigator.pop(context);
    // AI 추천 로직 (간단한 규칙 기반)
    final recommendation = _calculateRecommendation(intensity);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 추천'),
        content: Text(recommendation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _calculateRecommendation(String intensity) {
    // 간단한 규칙 기반 추천 로직
    final lastSet = _currentBaseline.workoutSets?.firstOrNull;
    if (lastSet == null) return '추천 데이터가 없습니다.';

    switch (intensity) {
      case '어려움':
        return '다음 운동: ${lastSet.weight}kg × ${lastSet.reps}회 (무게 유지)';
      case '보통':
        return '다음 운동: ${lastSet.weight + 2.5}kg × ${lastSet.reps}회 (무게 증가)';
      case '낮음':
        return '다음 운동: ${lastSet.weight + 5}kg × ${lastSet.reps}회 (무게 증가)';
      default:
        return '추천 데이터가 없습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // _currentBaseline 사용
    final totalVolume = _calculateTotalVolume();

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBaseline.exerciseName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 영상 영역 (있으면 플레이어, 없으면 등록 버튼)
              if (_currentBaseline.videoUrl != null &&
                  _currentBaseline.videoUrl!.isNotEmpty)
                Card(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline,
                          size: 64, color: Colors.white),
                    ),
                  ),
                )
              else
                Card(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 1. [안전 장치] 비동기 작업 전에 Messenger 객체를 미리 확보 (Context 오류 방지)
                          final messenger = ScaffoldMessenger.of(context);

                          // 2. 영상 업로드 화면으로 이동 및 결과 대기
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoUploadScreen(
                                baseline: _currentBaseline,
                                isCheckpoint: false, // 후속 업로드 모드
                              ),
                            ),
                          );

                          // 3. [Early Return] 결과가 없거나(뒤로가기), 화면이 꺼졌으면 종료
                          if (result != true || !mounted) return;

                          try {
                            // 4. [실제 데이터 갱신] DB에서 최신 데이터를 가져옴
                            final repository =
                                ref.read(workoutRepositoryProvider);
                            final updatedBaseline = await repository
                                .getBaselineById(_currentBaseline.id);

                            // 5. 비동기 작업 후 화면이 살아있는지 한 번 더 체크
                            if (!mounted) return;

                            // 6. 데이터가 유효하면 화면 갱신 (플레이어 표시)
                            if (updatedBaseline != null) {
                              setState(() {
                                _currentBaseline = updatedBaseline;
                              });
                            }
                          } catch (e) {
                            // 7. [에러 처리] 미리 확보해둔 messenger를 사용하여 안전하게 스낵바 표시
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('데이터 갱신 중 오류가 발생했습니다: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.video_library, size: 48),
                        label: const Text(
                          '영상 지금 등록하기',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 총 볼륨 표시
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '총 볼륨',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalVolume.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 세트 정보 리스트 (인덱스 사용)
              if (_currentBaseline.workoutSets != null &&
                  _currentBaseline.workoutSets!.isNotEmpty)
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '세트 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._currentBaseline.workoutSets!
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final set = entry.value;
                        return ListTile(
                          title: Text('${set.weight}kg × ${set.reps}회'),
                          subtitle: Text('${index + 1}세트'),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // 자세 피드백 UI
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '자세 피드백',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentBaseline.feedbackPrompt ??
                            '관절 참여도가 근육 참여도보다 높습니다',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 운동 강도 피드백 버튼
              ElevatedButton.icon(
                onPressed: _showIntensityFeedback,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('운동 강도 피드백'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseAddScreen(
                            initialBaseline: _currentBaseline,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('다시하기'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckpointCameraScreen(
                            baseline: _currentBaseline,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('중간 점검'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
