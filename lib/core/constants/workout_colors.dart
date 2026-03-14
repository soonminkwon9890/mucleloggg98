import 'package:flutter/material.dart';

/// 운동 계획 색상 상수
///
/// 캘린더에서 운동 계획을 표시할 때 사용하는 색상 코드입니다.
/// colorHex 형태로 저장되어 DB와 통신합니다.
class WorkoutColors {
  // ============================================
  // 색상 Hex 코드 (DB 저장용)
  // ============================================

  /// 강도 높음 (빨간색)
  static const String highIntensityHex = '0xFFF44336';

  /// 보통 (파란색) - 기본값
  static const String normalHex = '0xFF2196F3';

  /// 컨디션 조절 (녹색)
  static const String conditionHex = '0xFF4CAF50';

  /// 유지 모드 / 루틴 계획 (보라색)
  static const String maintainHex = '0xFF9C27B0';

  /// 컨디션 조절 - 편집용 (노란색)
  static const String conditionEditHex = '0xFFFFEB3B';

  /// 휴식 (회색)
  static const String restHex = '0xFF9E9E9E';

  /// 수동 추가 (녹색) - conditionHex와 동일
  static const String manualAddHex = conditionHex;

  /// 기본 색상 (파란색)
  static const String defaultHex = normalHex;

  // ============================================
  // Color 객체 (UI 렌더링용)
  // ============================================

  /// 강도 높음 (빨간색)
  static const Color highIntensity = Color(0xFFF44336);

  /// 보통 (파란색)
  static const Color normal = Color(0xFF2196F3);

  /// 컨디션 조절 (녹색)
  static const Color condition = Color(0xFF4CAF50);

  /// 유지 모드 (보라색)
  static const Color maintain = Color(0xFF9C27B0);

  /// 컨디션 조절 - 편집용 (노란색)
  static const Color conditionEdit = Color(0xFFFFEB3B);

  /// 휴식 (회색)
  static const Color rest = Color(0xFF9E9E9E);

  // ============================================
  // 캘린더 마커 색상 (과거 기록용)
  // ============================================

  /// 과거 운동 기록 마커 (회색)
  static const Color pastWorkoutMarker = Color(0xFFBDBDBD);

  // ============================================
  // 유틸리티 메서드
  // ============================================

  /// Hex 문자열을 Color로 변환
  ///
  /// [colorHex] 0xFF로 시작하는 색상 코드 (예: '0xFFF44336')
  static Color fromHex(String colorHex) {
    return Color(int.parse(colorHex));
  }

  /// Color를 Hex 문자열로 변환
  ///
  /// 반환: 0xFF로 시작하는 색상 코드
  static String toHex(Color color) {
    final argb = color.toARGB32();
    return '0x${argb.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  /// colorHex로 반투명 배경색 생성 (alpha 0.2)
  static Color getBackgroundColor(String colorHex) {
    return fromHex(colorHex).withValues(alpha: 0.2);
  }
}

/// 루틴 강도별 색상 매핑
///
/// RoutineIntensity enum과 연동하여 사용합니다.
class IntensityColors {
  /// 강도별 Hex 색상 맵
  static const Map<String, String> hexByIntensity = {
    'high': WorkoutColors.highIntensityHex,
    'normal': WorkoutColors.normalHex,
    'condition': WorkoutColors.conditionHex,
    'maintain': WorkoutColors.maintainHex,
  };

  /// 강도별 Color 맵
  static const Map<String, Color> colorByIntensity = {
    'high': WorkoutColors.highIntensity,
    'normal': WorkoutColors.normal,
    'condition': WorkoutColors.condition,
    'maintain': WorkoutColors.maintain,
  };

  /// 강도 이름으로 Hex 색상 가져오기
  static String getHex(String intensity) {
    return hexByIntensity[intensity] ?? WorkoutColors.defaultHex;
  }

  /// 강도 이름으로 Color 가져오기
  static Color getColor(String intensity) {
    return colorByIntensity[intensity] ?? WorkoutColors.normal;
  }
}
