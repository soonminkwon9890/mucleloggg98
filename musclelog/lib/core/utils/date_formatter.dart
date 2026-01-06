import 'package:intl/intl.dart';

/// 날짜 포맷 유틸리티
class DateFormatter {
  // 날짜만 표시 (예: 2025년 12월 11일)
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일', 'ko_KR').format(date);
  }

  // 날짜와 시간 표시 (예: 2025년 12월 11일 오후 7시 30분)
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy년 M월 d일 a h시 m분', 'ko_KR').format(date);
  }

  // 시간만 표시 (예: 오후 7시 30분)
  static String formatTime(DateTime date) {
    return DateFormat('a h시 m분', 'ko_KR').format(date);
  }

  // 상대 시간 표시 (예: 2시간 전, 어제, 3일 전)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return formatDate(date);
    }
  }

  // 날짜 그룹핑용 키 생성 (예: 2025-12-11)
  static String getDateGroupKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

