import 'package:flutter/material.dart';

/// 재사용 가능한 BottomSheet 컨테이너 위젯
///
/// 드래그 핸들, 둥근 모서리, SafeArea 처리를 포함합니다.
///
/// 사용 예시:
/// ```dart
/// await BottomSheetContainer.show(
///   context: context,
///   maxHeightRatio: 0.8,
///   builder: (context) => YourContentWidget(),
/// );
/// ```
class BottomSheetContainer extends StatelessWidget {
  final Widget child;
  final bool showDragHandle;
  final double maxHeightRatio;

  const BottomSheetContainer({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.maxHeightRatio = 0.67,
  });

  /// BottomSheet을 표시합니다.
  ///
  /// [context] - BuildContext
  /// [builder] - BottomSheet 내용을 빌드하는 함수
  /// [maxHeightRatio] - 화면 대비 최대 높이 비율 (기본값: 0.67, 즉 2/3)
  /// [showDragHandle] - 드래그 핸들 표시 여부 (기본값: true)
  /// [isScrollControlled] - 스크롤 컨트롤 여부 (기본값: true)
  ///
  /// 반환값: BottomSheet에서 반환된 값 (nullable)
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    double maxHeightRatio = 0.67,
    bool showDragHandle = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BottomSheetContainer(
          showDragHandle: showDragHandle,
          maxHeightRatio: maxHeightRatio,
          child: builder(sheetContext),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * maxHeightRatio;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) const _DragHandle(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 드래그 핸들 위젯
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
