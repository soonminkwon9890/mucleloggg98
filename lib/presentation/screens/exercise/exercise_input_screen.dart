import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../../data/models/workout_set.dart';
import '../../../domain/algorithms/one_rm_calculator.dart';
import '../../../core/enums/exercise_enums.dart';
import '../../widgets/common/rpe_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';

/// 운동 입력 화면 (Data First, Video Optional)
/// 영상 로직은 PostureAnalysisScreen으로 이동됨
class ExerciseInputScreen extends ConsumerStatefulWidget {
  final ExerciseBaseline? initialBaseline;

  const ExerciseInputScreen({
    super.key,
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

  int _rpe = 7;
  bool _isSaving = false;

  // 운동 분류 선택 상태
  BodyPart? _selectedBodyPart;
  MovementType? _selectedMovementType;

  @override
  void initState() {
    super.initState();
    _exerciseTitleController = TextEditingController(
      text: widget.initialBaseline?.exerciseName ?? '',
    );

    // 재기록 시 기존 분류 정보를 Enum으로 자동 선택
    if (widget.initialBaseline != null) {
      _selectedBodyPart = widget.initialBaseline!.bodyPart;
      _selectedMovementType = widget.initialBaseline!.movementType;
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

      // 영상 로직은 PostureAnalysisScreen으로 이동됨
      String? videoUrl;
      String? thumbnailUrl;

      // 현재 사용자 ID 가져오기
      final userId = ref.read(authRepositoryProvider).getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // Baseline 저장
      // [Phase 3.2.1] Enum 그대로 사용 (변환 함수 제거)
      final baseline = ExerciseBaseline(
        id: baselineId,
        userId: userId,
        exerciseName: _exerciseTitleController.text.trim(),
        targetMuscle: null,
        bodyPart: _selectedBodyPart, // Enum 직접 사용
        movementType: _selectedMovementType, // Enum 직접 사용
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        skeletonData: null, // 영상 로직은 PostureAnalysisScreen으로 이동됨
        createdAt: DateTime.now(),
      );

      final savedBaseline = await repository.upsertBaseline(baseline);

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
          rpeLevel: RpeLevelParsing.fromRpeValue(_rpe),
          estimated1rm: estimated1rm,
          isAiSuggested: false,
          createdAt: DateTime.now(),
        );

        await repository.upsertWorkoutSet(workoutSet);

        // created_at 겹침 방지를 위해 딜레이 추가
        if (i < totalSets - 1) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // [데이터 갱신] 저장 완료 후 Provider들을 무효화하여 최신 데이터를 받아오도록 함
      if (mounted) {
        ref.invalidate(baselinesProvider);
        ref.invalidate(workoutDatesProvider);
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
              // 영상 로직은 PostureAnalysisScreen으로 이동됨
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI 분석을 위해 영상을 업로드해주세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
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
                children: BodyPart.values.map((bodyPart) {
                  return FilterChip(
                    label: Text(bodyPart.label),
                    selected: _selectedBodyPart == bodyPart,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBodyPart = bodyPart;
                          // 하체나 전신으로 변경 시 movementType을 null로 초기화
                          if (bodyPart != BodyPart.upper) {
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
              if (_selectedBodyPart == BodyPart.upper) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: MovementType.values.map((movementType) {
                    return FilterChip(
                      label: Text(movementType.label),
                      selected: _selectedMovementType == movementType,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMovementType = movementType;
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
