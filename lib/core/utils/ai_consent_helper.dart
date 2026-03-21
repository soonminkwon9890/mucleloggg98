import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 코칭 데이터 전송에 대한 1회성 명시적 동의 처리 유틸리티
///
/// 개인정보 보호법(PIPA) 및 Google Gemini API 서비스 약관 준수를 위해
/// 사용자의 운동 데이터를 외부 AI 서비스로 전송하기 전에 반드시 이 헬퍼를 통해
/// 동의를 확인해야 합니다.
///
/// 사용 방법:
/// ```dart
/// Future<void> _handleAiCoachingRequest() async {
///   final consented = await AiConsentHelper.ensureConsent(context);
///   if (!consented || !mounted) return;
///   await _actualAiMethod();
/// }
/// ```
class AiConsentHelper {
  AiConsentHelper._();

  /// SharedPreferences 키 — 변경 시 기존 동의 상태가 초기화되므로 주의.
  static const String _prefKey = 'has_agreed_to_ai_coaching';

  /// 동의 여부를 확인하고, 미동의 상태이면 동의 다이얼로그를 표시합니다.
  ///
  /// 반환값:
  /// - `true`  : 이미 동의한 이력이 있거나, 방금 "동의하고 분석하기"를 탭함 → AI 호출 진행
  /// - `false` : 동의한 이력 없음 + "취소"를 탭했거나 context가 unmount 됨 → AI 호출 중단
  static Future<bool> ensureConsent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAgreed = prefs.getBool(_prefKey) ?? false;
    if (alreadyAgreed) return true;

    // context 유효성 재확인 (async gap 이후)
    if (!context.mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('AI 코칭 데이터 전송 동의'),
        content: const Text(
          '정확한 AI 코칭 및 분석을 위해 고객님의 운동 기록(종목, 무게, 횟수, 강도 등)이 '
          'Google Gemini AI 서비스로 전송됩니다.\n\n'
          '전송된 데이터는 맞춤 운동 계획 생성에만 사용되며, '
          'Google의 개인정보처리방침이 적용됩니다.\n\n'
          '동의하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('동의하고 분석하기'),
          ),
        ],
      ),
    );

    if (agreed != true) return false;

    // 동의 상태를 영구 저장 — 이후 호출에서 다이얼로그를 표시하지 않습니다.
    await prefs.setBool(_prefKey, true);
    return true;
  }

  /// 테스트 또는 개인정보 설정 화면에서 동의를 초기화할 때 사용합니다.
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
