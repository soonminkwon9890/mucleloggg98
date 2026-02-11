import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// iOS/Android 플랫폼별 적응형 위젯 유틸리티
/// 
/// iOS에서는 Cupertino 스타일, Android에서는 Material 스타일을 사용합니다.
class AdaptiveWidgets {
  /// 현재 플랫폼이 iOS인지 확인 (Web 환경 제외)
  static bool get _isIOS => !kIsWeb && Platform.isIOS;

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

    if (_isIOS) {
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
    if (_isIOS) {
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
    if (_isIOS) {
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

    if (_isIOS) {
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

  /// 플랫폼별 적응형 날짜 선택기
  /// 
  /// iOS에서는 CupertinoDatePicker, Android에서는 Material showDatePicker를 사용합니다.
  static Future<DateTime?> showAdaptiveDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? confirmText,
    String? cancelText,
  }) async {
    confirmText ??= '확인';
    cancelText ??= '취소';

    if (_isIOS) {
      DateTime? selectedDate = initialDate;
      
      final result = await showCupertinoModalPopup<DateTime?>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              // 상단 버튼 영역
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(cancelText!),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(confirmText!),
                      onPressed: () => Navigator.pop(context, selectedDate),
                    ),
                  ],
                ),
              ),
              // 날짜 선택기
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) => selectedDate = date,
                ),
              ),
            ],
          ),
        ),
      );
      
      return result;
    } else {
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        confirmText: confirmText,
        cancelText: cancelText,
      );
    }
  }

  /// 플랫폼별 적응형 시간 선택기
  /// 
  /// iOS에서는 CupertinoDatePicker, Android에서는 Material showTimePicker를 사용합니다.
  static Future<TimeOfDay?> showAdaptiveTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    String? confirmText,
    String? cancelText,
  }) async {
    confirmText ??= '확인';
    cancelText ??= '취소';

    if (_isIOS) {
      DateTime selectedDateTime = DateTime(
        2000, 1, 1, initialTime.hour, initialTime.minute,
      );
      
      final result = await showCupertinoModalPopup<TimeOfDay?>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              // 상단 버튼 영역
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(cancelText!),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(confirmText!),
                      onPressed: () => Navigator.pop(
                        context,
                        TimeOfDay.fromDateTime(selectedDateTime),
                      ),
                    ),
                  ],
                ),
              ),
              // 시간 선택기
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selectedDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (date) => selectedDateTime = date,
                ),
              ),
            ],
          ),
        ),
      );
      
      return result;
    } else {
      return showTimePicker(
        context: context,
        initialTime: initialTime,
        confirmText: confirmText,
        cancelText: cancelText,
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
