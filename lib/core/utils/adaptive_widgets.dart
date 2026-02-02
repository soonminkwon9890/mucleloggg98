import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS/Android 플랫폼별 적응형 위젯 유틸리티
/// 
/// iOS에서는 Cupertino 스타일, Android에서는 Material 스타일을 사용합니다.
class AdaptiveWidgets {
  /// 플랫폼별 적응형 다이얼로그 표시
  /// 
  /// iOS에서는 CupertinoAlertDialog, Android에서는 AlertDialog를 사용합니다.
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool destructive = false,
  }) {
    confirmText ??= '확인';
    cancelText ??= '취소';

    if (Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              child: Text(cancelText!),
            ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              onPressed: () {
                Navigator.pop(context, true as T);
                onConfirm?.call();
              },
              child: Text(confirmText!),
            ),
          ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              child: Text(cancelText!),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true as T);
                onConfirm?.call();
              },
              style: destructive
                  ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              child: Text(confirmText!),
            ),
          ],
        ),
      );
    }
  }

  /// 플랫폼별 적응형 로딩 인디케이터
  /// 
  /// iOS에서는 CupertinoActivityIndicator, Android에서는 CircularProgressIndicator를 반환합니다.
  static Widget buildAdaptiveLoadingIndicator({
    double? radius,
    double? strokeWidth,
    Color? color,
  }) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: radius ?? 10.0,
        color: color,
      );
    } else {
      return CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 4.0,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      );
    }
  }

  /// 플랫폼별 적응형 작은 로딩 인디케이터 (버튼 내부용)
  static Widget buildSmallLoadingIndicator({Color? color}) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: 10,
        color: color,
      );
    } else {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
        ),
      );
    }
  }

  /// 플랫폼별 적응형 액션 시트 표시
  /// 
  /// iOS에서는 CupertinoActionSheet, Android에서는 BottomSheet를 사용합니다.
  static Future<T?> showAdaptiveActionSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveAction> actions,
    String? cancelText,
  }) {
    cancelText ??= '취소';

    if (Platform.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: actions
              .map((action) => CupertinoActionSheetAction(
                    isDestructiveAction: action.isDestructive,
                    onPressed: () {
                      Navigator.pop(context, action.value as T);
                      action.onPressed?.call();
                    },
                    child: Text(action.label),
                  ))
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText!),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ...actions.map((action) => ListTile(
                    title: Text(
                      action.label,
                      style: TextStyle(
                        color: action.isDestructive ? Colors.red : null,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, action.value as T);
                      action.onPressed?.call();
                    },
                  )),
            ],
          ),
        ),
      );
    }
  }
}

/// 액션 시트 항목 모델
class AdaptiveAction {
  final String label;
  final dynamic value;
  final bool isDestructive;
  final VoidCallback? onPressed;

  const AdaptiveAction({
    required this.label,
    this.value,
    this.isDestructive = false,
    this.onPressed,
  });
}
