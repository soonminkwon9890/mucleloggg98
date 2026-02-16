import 'package:flutter/material.dart';
import 'package:musclelog/presentation/screens/subscription/subscription_screen.dart';

/// 모든 유료 기능 제한 시 재사용하는 표준 다이얼로그
/// - Title: "프리미엄 전용 기능"
/// - Content: 기본값 또는 맞춤 메시지
/// - Actions: [취소] / [결제창으로 이동하기]
/// - 반환: Future<bool?> - 결제 성공 시 true, 취소 또는 미완료 시 null/false
Future<bool?> showPremiumGuidanceDialog(
  BuildContext context, {
  String message = '해당 기능을 이용하려면 프리미엄 멤버십 가입이 필요합니다.\n결제 페이지로 이동하시겠습니까?',
}) async {
  if (!context.mounted) return null;

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
