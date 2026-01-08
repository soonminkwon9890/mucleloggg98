import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../workout/main_screen.dart';

/// 프로필 설정 화면
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedExperienceLevel;
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _experienceLevels = [
    {'value': AppConstants.experienceBeginner, 'label': '초급'},
    {'value': AppConstants.experienceIntermediate, 'label': '중급'},
    {'value': AppConstants.experienceAdvanced, 'label': '고급'},
  ];

  final _genders = [
    {'value': 'MALE', 'label': '남성'},
    {'value': 'FEMALE', 'label': '여성'},
  ];

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime initialDate = _selectedBirthDate ?? 
        DateTime.now().subtract(const Duration(days: 365 * 25));
    DateTime? selectedDate = _selectedBirthDate;
    
    await showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedDate != null) {
                        setState(() {
                          _selectedBirthDate = selectedDate;
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
              SizedBox(
                height: 250,
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1900),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExperienceLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동 경력을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authRepositoryProvider).getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      final profile = UserProfile(
        id: userId,
        experienceLevel: _selectedExperienceLevel,
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        createdAt: DateTime.now(),
      );

      await ref.read(authRepositoryProvider).saveProfile(profile);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 설정'),
        ),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '운동 경력을 선택해주세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '선택한 경력에 따라 AI 추천 강도가 조정됩니다',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                RadioGroup<String>(
                  groupValue: _selectedExperienceLevel,
                  onChanged: (value) {
                    setState(() => _selectedExperienceLevel = value);
                  },
                  child: Column(
                    children: _experienceLevels.map((level) {
                      final isSelected =
                          _selectedExperienceLevel == level['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RadioListTile<String>(
                          title: Text(level['label']!),
                          value: level['value']!,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '생년월일',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
                          : '생년월일을 선택하세요',
                      style: TextStyle(
                        color: _selectedBirthDate != null
                            ? null
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() => _selectedGender = value);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '성별',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _genders.map((gender) {
                          final isSelected = _selectedGender == gender['value'];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: RadioListTile<String>(
                                title: Text(gender['label']!),
                                value: gender['value']!,
                                contentPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: '키 (cm)',
                    border: OutlineInputBorder(),
                    hintText: '예: 175',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final height = double.tryParse(value);
                      if (height == null) {
                        return '올바른 숫자를 입력해주세요';
                      }
                      if (height < 50 || height > 250) {
                        return '50cm ~ 250cm 사이의 값을 입력해주세요';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: '몸무게 (kg)',
                    border: OutlineInputBorder(),
                    hintText: '예: 70',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final weight = double.tryParse(value);
                      if (weight == null) {
                        return '올바른 숫자를 입력해주세요';
                      }
                      if (weight < 20 || weight > 300) {
                        return '20kg ~ 300kg 사이의 값을 입력해주세요';
                      }
                    }
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('시작하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
