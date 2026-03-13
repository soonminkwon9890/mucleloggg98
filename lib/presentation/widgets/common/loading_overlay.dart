import 'package:flutter/material.dart';

/// 로딩 상태를 오버레이로 표시하는 위젯
///
/// 자식 위젯 위에 반투명 배경과 로딩 인디케이터를 표시합니다.
///
/// 사용 예시:
/// ```dart
/// LoadingOverlay(
///   isLoading: _isSubmitting,
///   child: Form(...),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? overlayColor;
  final double overlayOpacity;
  final Widget? loadingWidget;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.overlayColor,
    this.overlayOpacity = 0.5,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: (overlayColor ?? Colors.black).withValues(alpha: overlayOpacity),
              child: Center(
                child: loadingWidget ?? const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

/// 전체 화면 로딩 상태를 표시하는 위젯
///
/// 데이터 로딩 중일 때 전체 화면에 로딩 인디케이터를 표시합니다.
///
/// 사용 예시:
/// ```dart
/// if (isLoading) {
///   return const FullScreenLoading();
/// }
/// return actualContent;
/// ```
class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 버튼 내부에 표시되는 작은 로딩 인디케이터
///
/// ElevatedButton, TextButton 등의 child로 사용합니다.
///
/// 사용 예시:
/// ```dart
/// ElevatedButton(
///   onPressed: _isLoading ? null : _submit,
///   child: _isLoading
///       ? const ButtonLoadingIndicator()
///       : const Text('저장'),
/// )
/// ```
class ButtonLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const ButtonLoadingIndicator({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
      ),
    );
  }
}
