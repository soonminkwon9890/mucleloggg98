import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../domain/algorithms/one_rm_calculator.dart';
import '../../../video/ml_kit/pose_detector.dart';
import '../../../core/utils/media_helper.dart';
import '../../../core/utils/video_compressor.dart';
import '../../../core/utils/exercise_category_helper.dart';
import '../../widgets/common/rpe_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import 'media_source_modal.dart';

/// 운동 입력 화면 (Data First, Video Optional)
class ExerciseInputScreen extends ConsumerStatefulWidget {
  final File? videoFile;
  final File? thumbnailFile;
  final ExerciseBaseline? initialBaseline;

  const ExerciseInputScreen({
    super.key,
    this.videoFile,
    this.thumbnailFile,
    this.initialBaseline,
  });

  @override
  ConsumerState<ExerciseInputScreen> createState() =>
      _ExerciseInputScreenState();
}

class _ExerciseInputScreenState extends ConsumerState<ExerciseInputScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _exerciseTitleController;
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];

  File? _selectedVideo;
  File? _thumbnailFile;
  bool _isProcessingVideo = false;
  int _rpe = 7;
  bool _isSaving = false;
  
  // 운동 분류 선택 상태
  String? _selectedBodyPart; // '상체', '하체', '전신'
  String? _selectedMovementType; // '밀기', '당기기' - 상체 선택 시에만 활성화

  @override
  void initState() {
    super.initState();
    _exerciseTitleController = TextEditingController(
      text: widget.initialBaseline?.exerciseName ?? '',
    );
    _selectedVideo = widget.videoFile;
    _thumbnailFile = widget.thumbnailFile;
    
    // 재기록 시 기존 분류 정보를 한글로 변환하여 자동 선택
    if (widget.initialBaseline != null) {
      _selectedBodyPart = ExerciseCategoryHelper.getKoreanFromBodyPart(
        widget.initialBaseline!.bodyPart,
      );
      if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
        _selectedMovementType = ExerciseCategoryHelper.getKoreanFromMovementType(
          widget.initialBaseline!.movementType,
        );
      }
    }
    
    // 첫 세트 추가
    _addSet();
  }

  @override
  void dispose() {
    _exerciseTitleController.dispose();
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() {
      // 직전 세트의 값을 복사 (첫 세트는 빈 값)
      String? lastWeight;
      String? lastReps;

      if (_weightControllers.isNotEmpty && _repsControllers.isNotEmpty) {
        lastWeight = _weightControllers.last.text;
        lastReps = _repsControllers.last.text;
      }

      _weightControllers.add(TextEditingController(text: lastWeight ?? ''));
      _repsControllers.add(TextEditingController(text: lastReps ?? ''));
    });
  }

  void _removeSet(int index) {
    setState(() {
      _weightControllers[index].dispose();
      _repsControllers[index].dispose();
      _weightControllers.removeAt(index);
      _repsControllers.removeAt(index);
    });
  }

  Future<void> _selectVideoSource(String source) async {
    try {
      File? videoFile;

      if (source == 'camera') {
        videoFile = await MediaHelper.pickVideoFromCamera();
      } else if (source == 'gallery') {
        videoFile = await MediaHelper.pickVideoFromGallery();
      }

      if (videoFile != null) {
        setState(() {
          _isProcessingVideo = true;
        });

        // 영상 압축 및 썸네일 생성
        final compressor = VideoCompressor();
        final compressedVideo = await compressor.compressVideo(videoFile);
        final thumbnail = await compressor.generateThumbnail(videoFile);

        if (mounted) {
          setState(() {
            _isProcessingVideo = false;
            _thumbnailFile = thumbnail;
            final compressedPath = compressedVideo?.path;
            if (compressedPath != null) {
              _selectedVideo = File(compressedPath);
            } else {
              _selectedVideo = videoFile;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingVideo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  void _showVideoSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MediaSourceModal(
        onSourceSelected: _selectVideoSource,
      ),
    );
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _thumbnailFile = null;
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    if (_weightControllers.isEmpty || _repsControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 세트를 추가해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final baselineId = const Uuid().v4();

      // 스켈레톤 데이터 추출 (썸네일이 있는 경우에만)
      Map<String, dynamic>? skeletonData;
      String? videoUrl;
      String? thumbnailUrl;

      if (_thumbnailFile != null) {
        try {
          final poseDetector = PoseDetectionService();
          skeletonData =
              await poseDetector.extractPoseFromImage(_thumbnailFile!);
          await poseDetector.dispose();
        } catch (e) {
          debugPrint('스켈레톤 추출 실패: $e');
          skeletonData = null;
        }
      }

      // 영상이 있는 경우에만 업로드
      if (_selectedVideo != null) {
        videoUrl = await repository.uploadVideo(_selectedVideo!, baselineId);
        if (_thumbnailFile != null) {
          thumbnailUrl =
              await repository.uploadThumbnail(_thumbnailFile!, baselineId);
        }
      }

      // 현재 사용자 ID 가져오기
      final userId = ref.read(authRepositoryProvider).getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 한글 값을 영문으로 변환하여 저장
      final bodyPartEn = _selectedBodyPart != null && _selectedBodyPart!.isNotEmpty
          ? ExerciseCategoryHelper.getBodyPartFromKorean(_selectedBodyPart!)
          : null;
      
      // 상체 선택 시에만 movementType 변환, 없으면 null
      final movementTypeEn = _selectedBodyPart == '상체' &&
              _selectedMovementType != null &&
              _selectedMovementType!.isNotEmpty
          ? ExerciseCategoryHelper.getMovementTypeFromKorean(_selectedMovementType!)
          : null;

      // Baseline 저장
      final baseline = ExerciseBaseline(
        id: baselineId,
        userId: userId,
        exerciseName: _exerciseTitleController.text.trim(),
        targetMuscle: null,
        bodyPart: bodyPartEn,
        movementType: movementTypeEn,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        skeletonData: skeletonData,
        createdAt: DateTime.now(),
      );

      final savedBaseline = await repository.saveBaseline(baseline);

      // 모든 세트 저장
      final totalSets = _weightControllers.length;
      for (int i = 0; i < totalSets; i++) {
        final weight = double.parse(_weightControllers[i].text);
        final reps = int.parse(_repsControllers[i].text);
        final estimated1rm = OneRMCalculator.calculate1RM(weight, reps, _rpe);

        final workoutSet = WorkoutSet(
          id: const Uuid().v4(),
          baselineId: savedBaseline.id,
          weight: weight,
          reps: reps,
          sets: totalSets, // 총 세트 수
          rpe: _rpe,
          rpeLevel: OneRMCalculator.getRpeLevel(_rpe),
          estimated1rm: estimated1rm,
          isAiSuggested: false,
          createdAt: DateTime.now(),
        );

        await repository.saveWorkoutSet(workoutSet);

        // created_at 겹침 방지를 위해 딜레이 추가
        if (i < totalSets - 1) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운동이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 정보 입력'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 영상 추가 영역 (Placeholder)
              Card(
                child: SizedBox(
                  height: 200,
                  child: _isProcessingVideo
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('영상을 처리하는 중...'),
                            ],
                          ),
                        )
                      : _thumbnailFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _thumbnailFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.white),
                                    onPressed: _removeVideo,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.video_library,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '영상 추가하기 (선택)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showVideoSourceModal,
                                    icon: const Icon(Icons.add),
                                    label: const Text('영상 선택'),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // 운동 제목 입력
              TextFormField(
                controller: _exerciseTitleController,
                decoration: const InputDecoration(
                  labelText: '운동 제목',
                  border: OutlineInputBorder(),
                  hintText: '예: 아침 스쿼트, 벤치프레스 등',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '운동 제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 운동 분류 선택 (상체/하체/전신)
              const Text(
                '운동 분류',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['상체', '하체', '전신'].map((part) {
                  return FilterChip(
                    label: Text(part),
                    selected: _selectedBodyPart == part,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBodyPart = part;
                          // 하체나 전신으로 변경 시 movementType을 null로 초기화
                          if (part != '상체') {
                            _selectedMovementType = null;
                          }
                        } else {
                          _selectedBodyPart = null;
                          _selectedMovementType = null;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              
              // 상체 선택 시에만 밀기/당기기 칩 표시
              if (_selectedBodyPart == '상체') ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: ['밀기', '당기기'].map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: _selectedMovementType == type,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMovementType = type;
                          } else {
                            _selectedMovementType = null;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 세트 리스트
              ...List.generate(_weightControllers.length, (index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightControllers[index],
                            decoration: const InputDecoration(
                              labelText: '무게 (kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '무게를 입력해주세요';
                              }
                              if (double.tryParse(value) == null) {
                                return '올바른 숫자를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _repsControllers[index],
                            decoration: const InputDecoration(
                              labelText: '횟수',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '횟수를 입력해주세요';
                              }
                              if (int.tryParse(value) == null) {
                                return '올바른 숫자를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _weightControllers.length > 1
                              ? () => _removeSet(index)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // 세트 추가 버튼
              ElevatedButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: const Text('세트 추가'),
              ),
              const SizedBox(height: 24),

              // RPE 선택
              RPESelector(
                value: _rpe,
                onChanged: (value) {
                  setState(() => _rpe = value);
                },
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExercise,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
