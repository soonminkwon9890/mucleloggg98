import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 주간 루틴 플래너 데이터 전송에 대한 1회성 명시적 동의 처리 유틸리티
///
/// AI 코칭과는 별도의 동의 키를 사용합니다.
/// 키: 'has_agreed_to_planner_v1'
class PlannerConsentHelper {
  PlannerConsentHelper._();

  static const String _prefKey = 'has_agreed_to_planner_v1';

  /// 동의 여부를 확인하고, 미동의 상태이면 동의 다이얼로그를 표시합니다.
  ///
  /// 반환값:
  /// - `true`  : 이미 동의했거나 지금 동의함 → 플래너 화면으로 진행
  /// - `false` : 동의 거부 또는 unmounted → 진행 중단
  static Future<bool> ensureConsent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAgreed = prefs.getBool(_prefKey) ?? false;
    if (alreadyAgreed) return true;

    if (!context.mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('주간 루틴 플래너 데이터 전송 동의'),
        content: const Text(
          '보다 정확한 AI 코칭 및 주간 루틴 구성을 위해 고객님의 과거 운동 기록(종목, 무게, 횟수, 강도, 요일별 패턴 등)이 '
          'Google(Gemini) 서버로 전송되어 처리됩니다.\n\n'
          '동의하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('동의하고 시작하기'),
          ),
        ],
      ),
    );

    if (agreed != true) return false;

    await prefs.setBool(_prefKey, true);
    return true;
  }

  /// 동의 철회 (개인정보 설정 화면 또는 테스트에서 사용)
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
