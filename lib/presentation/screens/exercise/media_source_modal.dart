import 'package:flutter/material.dart';

/// 미디어 소스 선택 모달
class MediaSourceModal extends StatelessWidget {
  final Function(String source) onSourceSelected;

  const MediaSourceModal({
    super.key,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '영상 소스 선택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt,
                  label: '카메라 촬영',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    onSourceSelected('camera');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library,
                  label: '앨범 선택',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    onSourceSelected('gallery');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.5),),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

