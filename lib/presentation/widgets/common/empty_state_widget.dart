import 'package:flutter/material.dart';

/// 데이터가 없을 때 표시하는 빈 상태 위젯
///
/// 일관된 빈 상태 UI를 제공합니다.
/// 아이콘, 제목, 부제목(선택), 액션 버튼(선택)을 표시할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.fitness_center,
///   title: '루틴에 운동이 없습니다',
///   actionLabel: '운동 추가하기',
///   onAction: () => _showAddExerciseModal(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.iconSize = 48,
    this.iconColor,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// 카드로 감싼 빈 상태 위젯
///
/// 카드 UI 내에서 빈 상태를 표시할 때 사용합니다.
///
/// 사용 예시:
/// ```dart
/// EmptyStateCard(
///   icon: Icons.bar_chart,
///   title: '아직 수행 기록이 없습니다',
/// )
/// ```
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final double iconSize;
  final Color? iconColor;
  final double? height;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.iconSize = 48,
    this.iconColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      actionIcon: actionIcon,
      iconSize: iconSize,
      iconColor: iconColor,
    );

    if (height != null) {
      content = SizedBox(
        height: height,
        child: Center(child: content),
      );
    }

    return Card(child: content);
  }
}

/// 전체 화면 빈 상태 위젯
///
/// 화면 전체가 빈 상태일 때 사용합니다.
///
/// 사용 예시:
/// ```dart
/// FullScreenEmptyState(
///   icon: Icons.search_off,
///   title: '검색 결과가 없습니다',
///   subtitle: '다른 검색어를 시도해 보세요',
/// )
/// ```
class FullScreenEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final double iconSize;
  final Color? iconColor;

  const FullScreenEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyStateWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
        actionIcon: actionIcon,
        iconSize: iconSize,
        iconColor: iconColor,
      ),
    );
  }
}
