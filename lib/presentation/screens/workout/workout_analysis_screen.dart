import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../providers/workout_provider.dart';
import '../../../data/models/exercise_baseline.dart';
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

  // 영상 플레이어 컨트롤러
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // initState에서 초기화
    _currentBaseline = widget.baseline;
    _initializeVideo();
    _checkIntensityFeedback();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = _currentBaseline.videoUrl;

    // 영상이 없으면 초기화하지 않음
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    '영상 재생 오류',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );

        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
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

  Future<void> _checkIntensityFeedback() async {
    final repository = ref.read(workoutRepositoryProvider);
    final frequency = await repository.getExerciseFrequency(_currentBaseline.id);

    // 3일 이상 수행한 경우에만 피드백 다이얼로그 표시
    if (frequency >= 3) {
      // 화면이 로드된 후에 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showIntensityFeedback();
        }
      });
    }
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
    final lastSet = _currentBaseline.workoutSets?.firstOrNull;
    if (lastSet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천 데이터가 없습니다.')),
      );
      return;
    }

    // 추천 값 계산
    final (recommendedWeight, recommendedReps) = _calculateRecommendation(
      intensity,
      lastSet.weight,
      lastSet.reps,
    );
    final recommendationText = _getRecommendationText(
      intensity,
      recommendedWeight,
      recommendedReps,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 추천'),
        content: Text(recommendationText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              // [안전 장치] 비동기 작업 전에 객체들을 미리 확보
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                // 추천 값으로 운동 추가
                await ref.read(workoutRepositoryProvider).addTodayWorkout(
                      _currentBaseline,
                      initialWeight: recommendedWeight,
                      initialReps: recommendedReps,
                    );

                if (!mounted) return;

                // Provider 갱신
                ref.invalidate(baselinesProvider);
                ref.invalidate(workoutDatesProvider);

                navigator.pop(); // 다이얼로그 닫기
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('오늘의 운동에 추가되었습니다!'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                );
              }
            },
            child: const Text('오늘의 운동에 추가'),
          ),
        ],
      ),
    );
  }

  /// 추천 무게와 횟수를 계산하여 반환합니다.
  (double weight, int reps) _calculateRecommendation(
    String intensity,
    double currentWeight,
    int currentReps,
  ) {
    switch (intensity) {
      case '어려움':
        return (currentWeight, currentReps); // 무게 유지
      case '보통':
        return (currentWeight + 2.5, currentReps); // 무게 증가
      case '낮음':
        return (currentWeight + 5.0, currentReps); // 무게 증가
      default:
        return (currentWeight, currentReps);
    }
  }

  /// 추천 텍스트를 생성합니다.
  String _getRecommendationText(
    String intensity,
    double weight,
    int reps,
  ) {
    String description;
    switch (intensity) {
      case '어려움':
        description = '무게 유지';
        break;
      case '보통':
        description = '무게 증가';
        break;
      case '낮음':
        description = '무게 증가';
        break;
      default:
        description = '';
    }
    return '다음 운동: ${weight}kg × $reps회 ($description)';
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isInitializing
                        ? Container(
                            height: 250,
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          )
                        : _hasError || _chewieController == null
                            ? Container(
                                height: 250,
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.white, size: 48),
                                      SizedBox(height: 8),
                                      Text(
                                        '영상 재생 불가',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Chewie(controller: _chewieController!),
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
                              // 영상이 업데이트되었으면 플레이어 재초기화
                              _chewieController?.dispose();
                              _videoController?.dispose();
                              _initializeVideo();
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

              // 자세 피드백 UI (영상이 있을 때만 표시)
              if (_currentBaseline.videoUrl != null &&
                  _currentBaseline.videoUrl!.isNotEmpty)
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
                          _currentBaseline.feedbackPrompt ?? '분석 준비 중입니다.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI 분석',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI 분석을 위해 영상을 업로드해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
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
                    onPressed: () async {
                      // [안전 장치] 비동기 작업 전에 객체들을 미리 확보
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      try {
                        // 현재 운동을 오늘의 운동에 추가 (기본값 0으로)
                        await ref
                            .read(workoutRepositoryProvider)
                            .addTodayWorkout(
                              _currentBaseline,
                            );

                        if (!mounted) return;

                        // Provider 갱신
                        ref.invalidate(baselinesProvider);
                        ref.invalidate(workoutDatesProvider);

                        // 홈 화면으로 돌아가기
                        navigator.popUntil((route) => route.isFirst);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('오늘의 운동에 추가되었습니다!'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('오류가 발생했습니다: $e')),
                        );
                      }
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
