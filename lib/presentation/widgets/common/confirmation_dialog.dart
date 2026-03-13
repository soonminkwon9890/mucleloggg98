import 'package:flutter/material.dart';

/// 재사용 가능한 확인 다이얼로그 위젯
///
/// 삭제, 취소, 확인 등의 작업에서 사용자의 동의를 구할 때 사용합니다.
///
/// 사용 예시:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context: context,
///   title: '삭제하시겠습니까?',
///   message: '이 항목을 삭제하면 복구할 수 없습니다.',
///   confirmText: '삭제',
///   confirmColor: Colors.red,
/// );
/// if (confirmed) { ... }
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final bool useElevatedButton;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.confirmColor,
    this.useElevatedButton = false,
  });

  /// 확인 다이얼로그를 표시하고 사용자의 선택을 반환합니다.
  ///
  /// [context] - BuildContext
  /// [title] - 다이얼로그 제목
  /// [message] - 간단한 텍스트 메시지 (content와 함께 사용 불가)
  /// [content] - 커스텀 위젯 내용 (message와 함께 사용 불가)
  /// [confirmText] - 확인 버튼 텍스트 (기본값: '확인')
  /// [cancelText] - 취소 버튼 텍스트 (기본값: '취소')
  /// [confirmColor] - 확인 버튼 색상 (삭제 작업의 경우 Colors.red 권장)
  /// [useElevatedButton] - true면 확인 버튼을 ElevatedButton으로 표시
  ///
  /// 반환값: 사용자가 확인을 선택하면 true, 취소 또는 외부 탭하면 false
  static Future<bool> show({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
    bool useElevatedButton = false,
  }) async {
    assert(
      message == null || content == null,
      'message와 content를 동시에 사용할 수 없습니다.',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        useElevatedButton: useElevatedButton,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content ?? (message != null ? Text(message!) : null),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        if (useElevatedButton)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
      ],
    );
  }
}
