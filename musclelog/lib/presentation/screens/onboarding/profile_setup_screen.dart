import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../workout/home_screen.dart';

/// 프로필 설정 화면
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedExperienceLevel;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _experienceLevels = [
    {'value': AppConstants.experienceBeginner, 'label': '초급'},
    {'value': AppConstants.experienceIntermediate, 'label': '중급'},
    {'value': AppConstants.experienceAdvanced, 'label': '고급'},
  ];

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
        createdAt: DateTime.now(),
      );

      await ref.read(authRepositoryProvider).saveProfile(profile);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
    return Scaffold(
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
    );
  }
}
