import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/exercise_baseline.dart';
import '../../providers/workout_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/enums/exercise_enums.dart';

/// 신규 운동 추가 패널
class ExerciseAddPanel extends ConsumerStatefulWidget {
  final VoidCallback onExerciseAdded;

  const ExerciseAddPanel({
    super.key,
    required this.onExerciseAdded,
  });

  @override
  ConsumerState<ExerciseAddPanel> createState() => _ExerciseAddPanelState();
}

class _ExerciseAddPanelState extends ConsumerState<ExerciseAddPanel> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  BodyPart? _selectedBodyPart;
  MovementType? _selectedMovementType;

  @override
  void dispose() {
    _exerciseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppBar(
                title: const Text('신규 운동 추가'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 운동 이름 입력
                      TextFormField(
                        controller: _exerciseNameController,
                        decoration: const InputDecoration(
                          labelText: '운동 이름 *',
                          border: OutlineInputBorder(),
                          hintText: '예: 벤치프레스',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '운동 이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // 부위 선택
                      const Text(
                        '부위 선택 *',
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
                                _selectedBodyPart = selected ? bodyPart : null;
                                // 부위가 변경되면 운동 타입 초기화
                                if (bodyPart != BodyPart.upper) {
                                  _selectedMovementType = null;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      // 운동 타입 (상체 선택 시에만 표시)
                      if (_selectedBodyPart == BodyPart.upper) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '운동 타입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: MovementType.values.map((movementType) {
                            return FilterChip(
                              label: Text(movementType.label),
                              selected: _selectedMovementType == movementType,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedMovementType = selected ? movementType : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveNewExercise,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNewExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBodyPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부위를 선택해주세요')),
      );
      return;
    }

    if (!mounted) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // [Phase 3.2.1] Enum 그대로 사용 (변환 함수 제거)
      final bodyPartCode = _selectedBodyPart?.code;
      final movementTypeCode = _selectedMovementType?.code;

      // [신규] 중복 체크
      final duplicate = await repository.findDuplicateBaseline(
        exerciseName: _exerciseNameController.text.trim(),
        bodyPart: bodyPartCode,
        movementType: movementTypeCode,
      );

      if (duplicate != null && mounted) {
        // 병합 다이얼로그 표시
        final mergeChoice = await _showMergeDialog(context, duplicate.exerciseName);
        if (mergeChoice == null) return; // 취소

        if (mergeChoice == true) {
          // 병합 선택: 기존 Baseline ID 재사용, 상태만 업데이트
          final updatedBaseline = duplicate.copyWith(
            isHiddenFromHome: false, // 홈에 보이게 변경
          );
          await repository.upsertBaseline(updatedBaseline);
          ref.invalidate(baselinesProvider);
          ref.invalidate(workoutDatesProvider);
          if (!mounted) return;
          widget.onExerciseAdded();
          return;
        }
        // false면 새로 생성 계속 진행
      }

      // 기존 저장 로직 (중복이 없거나 "새로 저장" 선택한 경우)
      // [Phase 3.2.1] Enum 그대로 사용 (변환 함수 제거)
      final newBaseline = ExerciseBaseline(
        id: const Uuid().v4(),
        userId: userId,
        exerciseName: _exerciseNameController.text.trim(),
        bodyPart: _selectedBodyPart, // Enum 직접 사용
        movementType: _selectedMovementType, // Enum 직접 사용
        createdAt: DateTime.now(),
      );

      await repository.addTodayWorkout(newBaseline);

      ref.invalidate(baselinesProvider);
      ref.invalidate(workoutDatesProvider);

      if (!mounted) return;

      widget.onExerciseAdded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  Future<bool?> _showMergeDialog(BuildContext context, String exerciseName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('중복 운동 발견'),
        content: Text(
          '보관함에 이미 "$exerciseName" 운동이 존재합니다.\n'
          '기존 운동 기록에 합쳐서 저장하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 새로 저장
            child: const Text('아니요 (별도 저장)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // 병합
            child: const Text('네 (합치기)'),
          ),
        ],
      ),
    );
  }
}

