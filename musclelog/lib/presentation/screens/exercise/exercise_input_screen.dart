import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../domain/algorithms/one_rm_calculator.dart';
import '../../../video/ml_kit/pose_detector.dart';
import '../../widgets/common/rpe_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';

/// 운동 입력 화면
class ExerciseInputScreen extends ConsumerStatefulWidget {
  final File videoFile;
  final File thumbnailFile;

  const ExerciseInputScreen({
    super.key,
    required this.videoFile,
    required this.thumbnailFile,
  });

  @override
  ConsumerState<ExerciseInputScreen> createState() =>
      _ExerciseInputScreenState();
}

class _ExerciseInputScreenState extends ConsumerState<ExerciseInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  String? _selectedBodyPart;
  String? _selectedMovementType;
  String? _selectedExerciseName;
  int _rpe = 7;
  bool _isSaving = false;

  final _bodyParts = [
    {'value': AppConstants.bodyPartUpper, 'label': '상체'},
    {'value': AppConstants.bodyPartLower, 'label': '하체'},
    {'value': AppConstants.bodyPartFull, 'label': '전신'},
  ];

  final _movementTypes = [
    {'value': AppConstants.movementTypePush, 'label': '밀기 (Push)'},
    {'value': AppConstants.movementTypePull, 'label': '당기기 (Pull)'},
  ];

  final _exerciseNames = [
    'BENCH_PRESS',
    'SQUAT',
    'DEADLIFT',
    'OVERHEAD_PRESS',
    'ROW',
    'PULL_UP',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBodyPart == null || _selectedExerciseName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final weight = double.parse(_weightController.text);
      final reps = int.parse(_repsController.text);

      // 1RM 계산
      final estimated1rm = OneRMCalculator.calculate1RM(weight, reps, _rpe);

      // 스켈레톤 데이터 추출 (썸네일에서)
      Map<String, dynamic>? skeletonData;
      try {
        final poseDetector = PoseDetectionService();
        skeletonData =
            await poseDetector.extractPoseFromImage(widget.thumbnailFile);
        await poseDetector.dispose();
      } catch (e) {
        // 스켈레톤 추출 실패해도 계속 진행
        debugPrint('스켈레톤 추출 실패: $e');
        skeletonData = null;
      }

      // 영상 및 썸네일 업로드
      final baselineId = DateTime.now().millisecondsSinceEpoch.toString();
      final videoUrl =
          await repository.uploadVideo(widget.videoFile, baselineId);
      final thumbnailUrl =
          await repository.uploadThumbnail(widget.thumbnailFile, baselineId);

      // 현재 사용자 ID 가져오기
      final userId = ref.read(authRepositoryProvider).getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // Baseline 저장
      final baseline = ExerciseBaseline(
        id: baselineId,
        userId: userId,
        exerciseName: _selectedExerciseName!,
        targetMuscle: _selectedBodyPart,
        bodyPart: _selectedBodyPart,
        movementType: _selectedMovementType,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        skeletonData: skeletonData,
        createdAt: DateTime.now(),
      );

      final savedBaseline = await repository.saveBaseline(baseline);

      // 첫 세트 기록 저장
      final workoutSet = WorkoutSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        baselineId: savedBaseline.id,
        weight: weight,
        reps: reps,
        rpe: _rpe,
        rpeLevel: OneRMCalculator.getRpeLevel(_rpe),
        estimated1rm: estimated1rm,
        isAiSuggested: false,
        createdAt: DateTime.now(),
      );

      await repository.saveWorkoutSet(workoutSet);

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
              // 썸네일 미리보기
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.thumbnailFile,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // 운동 종목 선택
              DropdownButtonFormField<String>(
                initialValue: _selectedExerciseName,
                decoration: const InputDecoration(
                  labelText: '운동 종목',
                  border: OutlineInputBorder(),
                ),
                items: _exerciseNames.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedExerciseName = value);
                },
                validator: (value) {
                  if (value == null) return '운동 종목을 선택해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 신체 부위 선택
              DropdownButtonFormField<String>(
                initialValue: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: '신체 부위',
                  border: OutlineInputBorder(),
                ),
                items: _bodyParts.map((part) {
                  return DropdownMenuItem(
                    value: part['value'],
                    child: Text(part['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBodyPart = value;
                    if (value == AppConstants.bodyPartUpper) {
                      _selectedMovementType = null; // 상체 선택 시 운동 타입 초기화
                    }
                  });
                },
                validator: (value) {
                  if (value == null) return '신체 부위를 선택해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 운동 타입 선택 (상체일 때만)
              if (_selectedBodyPart == AppConstants.bodyPartUpper)
                DropdownButtonFormField<String>(
                  initialValue: _selectedMovementType,
                  decoration: const InputDecoration(
                    labelText: '운동 타입',
                    border: OutlineInputBorder(),
                  ),
                  items: _movementTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedMovementType = value);
                  },
                ),
              if (_selectedBodyPart == AppConstants.bodyPartUpper)
                const SizedBox(height: 16),

              // 무게 입력
              TextFormField(
                controller: _weightController,
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
              const SizedBox(height: 16),

              // 횟수 입력
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: '횟수 (Reps)',
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
