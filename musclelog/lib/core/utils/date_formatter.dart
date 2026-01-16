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

  /// 두 날짜가 같은 날인지 문자열 비교로 확인 (시차 문제 완전 해결)
  /// [디버깅] 터미널에 비교 과정을 출력하여 문제 원인 파악
  /// [중요] DB에서 가져온 UTC 날짜를 로컬 시간으로 변환 후 비교
  static bool isSameDate(DateTime? dateA, DateTime? dateB) {
    // null 체크
    if (dateA == null || dateB == null) {
      return false;
    }

    // [중요] DB 날짜(UTC)를 로컬 시간으로 변환
    final localDateA = dateA.toLocal();
    final localDateB = dateB.toLocal();

    // yyyy-MM-dd 형식의 문자열로 변환
    final dateStrA = DateFormat('yyyy-MM-dd').format(localDateA);
    final dateStrB = DateFormat('yyyy-MM-dd').format(localDateB);

    // 문자열 비교로 같은 날인지 확인
    return dateStrA == dateStrB;
  }
}
