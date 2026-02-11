// 운동 관련 Enum 정의
// DB(String) ↔ 앱(Enum) 자동 변환 지원

enum BodyPart {
  upper, // 상체
  lower, // 하체
  full,  // 전신
}

extension BodyPartExtension on BodyPart {
  /// DB 저장용 코드 반환
  String get code {
    switch (this) {
      case BodyPart.upper:
        return 'UPPER';
      case BodyPart.lower:
        return 'LOWER';
      case BodyPart.full:
        return 'FULL';
    }
  }

  /// UI 표시용 한글 라벨 반환
  String get label {
    switch (this) {
      case BodyPart.upper:
        return '상체';
      case BodyPart.lower:
        return '하체';
      case BodyPart.full:
        return '전신';
    }
  }
}

extension BodyPartParsing on BodyPart {
  /// DB 코드로부터 Enum 생성 (nullable)
  /// [안전장치] 대소문자 무시, trim 적용, null 처리
  /// [Fail-safe] 알 수 없는 값이 들어와도 null 반환 (앱 크래시 방지)
  static BodyPart? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    switch (code.trim().toUpperCase()) {
      case 'UPPER':
        return BodyPart.upper;
      case 'LOWER':
        return BodyPart.lower;
      case 'FULL':
        return BodyPart.full;
      default:
        // print('Warning: Unknown BodyPart code: $code'); // 선택적 로그
        return null; // 안전하게 null 반환 (앱 크래시 방지)
    }
  }

  /// 한글 라벨로부터 Enum 생성 (nullable)
  static BodyPart? fromKorean(String korean) {
    switch (korean.trim()) {
      case '상체':
        return BodyPart.upper;
      case '하체':
        return BodyPart.lower;
      case '전신':
        return BodyPart.full;
      default:
        return null;
    }
  }
}

enum RpeLevel {
  low,    // 낮음
  medium, // 보통
  high,   // 높음
}

extension RpeLevelExtension on RpeLevel {
  /// DB 저장용 코드 반환
  String get code {
    switch (this) {
      case RpeLevel.low:
        return 'LOW';
      case RpeLevel.medium:
        return 'MEDIUM';
      case RpeLevel.high:
        return 'HIGH';
    }
  }

  /// UI 표시용 한글 라벨 반환
  String get label {
    switch (this) {
      case RpeLevel.low:
        return '낮음';
      case RpeLevel.medium:
        return '보통';
      case RpeLevel.high:
        return '높음';
    }
  }
}

extension RpeLevelParsing on RpeLevel {
  /// DB 코드로부터 Enum 생성 (nullable)
  /// [안전장치] 대소문자 무시, trim 적용, null 처리
  /// [Fail-safe] 알 수 없는 값이 들어와도 null 반환 (앱 크래시 방지)
  static RpeLevel? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    switch (code.trim().toUpperCase()) {
      case 'LOW':
        return RpeLevel.low;
      case 'MEDIUM':
        return RpeLevel.medium;
      case 'HIGH':
        return RpeLevel.high;
      default:
        // print('Warning: Unknown RpeLevel code: $code'); // 선택적 로그
        return null; // 안전하게 null 반환 (앱 크래시 방지)
    }
  }

  /// RPE 값(1-10)으로부터 Enum 추론 (nullable)
  /// RPE 범위: 1-4(낮음), 5-7(보통), 8-10(높음)
  static RpeLevel? fromRpeValue(int? rpeValue) {
    if (rpeValue == null) return null;
    if (rpeValue >= 1 && rpeValue <= 4) {
      return RpeLevel.low;
    } else if (rpeValue >= 5 && rpeValue <= 7) {
      return RpeLevel.medium;
    } else if (rpeValue >= 8 && rpeValue <= 10) {
      return RpeLevel.high;
    }
    return null;
  }
}
