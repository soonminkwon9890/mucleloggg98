import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/planner_consent_helper.dart';
import '../planner/weekly_routine_planner_screen.dart';

/// AI 코치 탭 화면
///
/// 사용자가 AI 기반 주간 루틴 플래너에 진입하는 단일 진입점입니다.
/// 기존 캘린더/리스트 뷰를 완전히 대체합니다.
class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  Future<void> _handleAiCoachingRequest(BuildContext context, WidgetRef ref) async {
    final consented = await PlannerConsentHelper.ensureConsent(context);
    if (!consented || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WeeklyRoutinePlannerScreen(
          selectedBaselineIds: {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // 헤드라인
              Text(
                '나만의 AI 주간 루틴 플래너',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // 서브헤드라인
              Text(
                '지난 운동 기록을 분석하여\n나에게 딱 맞는 다음 주 루틴을 만들어 드립니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 40),
              // CTA 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handleAiCoachingRequest(context, ref),
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text(
                    '✨ 다음 주 루틴 분석하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backward-compat alias so any import still resolving ProfileScreen compiles.
typedef ProfileScreen = AiCoachScreen;
