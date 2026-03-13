import 'package:flutter/material.dart';

/// 선택 가능한 리스트 타일 위젯
///
/// 체크박스와 함께 제목, 부제목, 선행 위젯을 표시합니다.
/// 운동 선택, 루틴 항목 선택 등에서 일관되게 사용됩니다.
///
/// 사용 예시:
/// ```dart
/// SelectableListTile(
///   isSelected: _selectedIds.contains(item.id),
///   onChanged: (selected) {
///     setState(() {
///       if (selected) {
///         _selectedIds.add(item.id);
///       } else {
///         _selectedIds.remove(item.id);
///       }
///     });
///   },
///   title: Text(item.name),
///   subtitle: Text(item.description),
///   leading: Icon(Icons.fitness_center),
/// )
/// ```
class SelectableListTile extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity controlAffinity;

  const SelectableListTile({
    super.key,
    required this.isSelected,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.contentPadding,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged != null ? (value) => onChanged!(value ?? false) : null,
      title: title,
      subtitle: subtitle,
      secondary: leading,
      contentPadding: contentPadding,
      controlAffinity: controlAffinity,
    );
  }
}

/// 이미지가 포함된 선택 가능한 리스트 타일
///
/// 운동 선택 시 썸네일 이미지를 함께 표시할 때 사용합니다.
///
/// 사용 예시:
/// ```dart
/// SelectableImageListTile(
///   isSelected: _selectedIds.contains(baseline.id),
///   onChanged: (selected) => _toggleSelection(baseline.id, selected),
///   title: baseline.exerciseName,
///   subtitle: baseline.targetMuscles?.join(', ') ?? '부위 미설정',
///   imageUrl: baseline.thumbnailUrl,
///   fallbackIcon: Icons.fitness_center,
/// )
/// ```
class SelectableImageListTile extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final IconData fallbackIcon;
  final double imageSize;
  final double imageBorderRadius;

  const SelectableImageListTile({
    super.key,
    required this.isSelected,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.fallbackIcon = Icons.fitness_center,
    this.imageSize = 50,
    this.imageBorderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged != null ? (value) => onChanged!(value ?? false) : null,
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      secondary: _buildLeadingImage(),
    );
  }

  Widget _buildLeadingImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(imageBorderRadius),
        child: Image.network(
          imageUrl!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(fallbackIcon, size: imageSize);
          },
        ),
      );
    }
    return Icon(fallbackIcon, size: imageSize);
  }
}
