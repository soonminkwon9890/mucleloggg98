import 'package:flutter/material.dart';
import 'package:musclelog/core/config/app_config.dart';
import 'package:musclelog/presentation/screens/subscription/subscription_screen.dart';

/// 모든 유료 기능 제한 시 재사용하는 표준 다이얼로그
/// - Title: "프리미엄 전용 기능"
/// - Content: 기본값 또는 맞춤 메시지
/// - Actions: [취소] / [결제창으로 이동하기]
/// - 반환: Future<bool?> - 결제 성공 시 true, 취소 또는 미완료 시 null/false
///
/// [Feature Flag] 결제 비활성화 시:
/// - 결제 화면으로 이동하지 않고 출시 기념 이벤트 안내 SnackBar 표시
/// - true를 반환하여 기능 사용 허용
Future<bool?> showPremiumGuidanceDialog(
  BuildContext context, {
  String message = '해당 기능을 이용하려면 프리미엄 멤버십 가입이 필요합니다.\n결제 페이지로 이동하시겠습니까?',
}) async {
  if (!context.mounted) return null;

  // [Feature Flag] 결제 비활성화 시 출시 기념 이벤트 안내 메시지 표시
  if (!AppConfig.isPaymentEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppConfig.betaFreeMessage),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    // true 반환하여 기능 접근 허용 (결제 완료로 처리)
    return true;
  }

  return showDialog<bool?>(
    context: context,
    builder: (BuildContext dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('프리미엄 전용 기능'),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, result == true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text('결제창으로 이동하기'),
          ),
        ],
      );
    },
  );
}

/// BuildContext extension for convenient dialog invocation
extension PremiumDialogX on BuildContext {
  Future<bool?> showPremiumDialog({String? message}) =>
      showPremiumGuidanceDialog(
        this,
        message: message ??
            '해당 기능을 이용하려면 프리미엄 멤버십 가입이 필요합니다.\n결제 페이지로 이동하시겠습니까?',
      );
}
