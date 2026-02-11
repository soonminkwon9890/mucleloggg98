import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../../core/enums/exercise_enums.dart';

/// 신규 운동 추가 패널
class ExerciseAddPanel extends ConsumerStatefulWidget {
  const ExerciseAddPanel({
    super.key,
    // onExerciseAdded 제거
  });

  @override
  ConsumerState<ExerciseAddPanel> createState() => _ExerciseAddPanelState();
}

class _ExerciseAddPanelState extends ConsumerState<ExerciseAddPanel> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  BodyPart? _selectedBodyPart;
  final List<String> _selectedTargetMuscles = [];

  static const Map<BodyPart, List<String>> _targetMusclesByBodyPart = {
    BodyPart.upper: ['가슴', '등', '어깨', '팔', '복근'],
    BodyPart.lower: ['대퇴사두(앞)', '햄스트링(뒤)', '둔근(힙)'],
    BodyPart.full: [], // 전신은 하위 선택 없음
  };

  @override
  void dispose() {
    _exerciseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Drawer 대신 Container 사용
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // 배경색만 지정
      ),
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
                                // [중요] 상위 부위가 변경되면 하위 타겟 근육 선택을 반드시 초기화
                                _selectedTargetMuscles.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // 타겟 근육 선택 (상체/하체 선택 시에만 표시)
                      if (_selectedBodyPart != null &&
                          _targetMusclesByBodyPart[_selectedBodyPart]!
                              .isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '타겟 근육 선택',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _targetMusclesByBodyPart[_selectedBodyPart]!
                              .map((muscle) => FilterChip(
                                    label: Text(muscle),
                                    selected:
                                        _selectedTargetMuscles.contains(muscle),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTargetMuscles.add(muscle);
                                        } else {
                                          _selectedTargetMuscles.remove(muscle);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
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

    // 3.1. 유효성 검사 추가 (Validation - 중요)
    // 운동 이름 체크
    final exerciseName = _exerciseNameController.text.trim();
    if (exerciseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동 이름을 입력해주세요.')),
      );
      return;
    }

    // 부위 체크
    if (_selectedBodyPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부위를 선택해주세요.')),
      );
      return;
    }

    // 타겟 근육 체크 (필수!)
    if (_selectedTargetMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타겟 근육을 최소 1개 이상 선택해주세요.')),
      );
      return;
    }

    if (!mounted) return;

    // 1. 키보드 내리기
    FocusScope.of(context).unfocus();

    // 2. 안전 딜레이
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      final viewModel = ref.read(homeViewModelProvider.notifier);
      final bodyPartCode = _selectedBodyPart!.code;

      // 3. 메모리 전용 추가 (DB 저장 X, Draft로 추가)
      viewModel.addNewExercise(
          exerciseName, bodyPartCode, _selectedTargetMuscles);

      // 4. mounted 체크
      if (!mounted || !context.mounted) return;

      // 5. 성공 신호(true)를 전달하며 패널 닫기
      // loadBaselines()는 호출하지 않음 (Draft 보존)
      Navigator.of(context).pop(true);
    } catch (e) {
      // 실패 시: 스낵바 표시 (패널은 닫지 않음)
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }
}
