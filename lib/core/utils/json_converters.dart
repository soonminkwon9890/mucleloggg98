import '../enums/exercise_enums.dart';

/// JSON 변환 유틸리티 클래스
/// 모델 파일의 중복된 변환 헬퍼 함수들을 중앙화
class JsonConverters {
  // ====================================================
  // 숫자 변환 메서드 (안전 장치 포함)
  // ====================================================

  /// dynamic 값을 double로 변환 (null이면 0.0)
  static double toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  /// dynamic 값을 double?로 변환 (null이면 null)
  static double? toDoubleNullable(dynamic value) => (value as num?)?.toDouble();

  /// dynamic 값을 int로 변환 (null이면 0)
  static int toInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  /// dynamic 값을 int?로 변환 (null이면 null)
  static int? toIntNullable(dynamic value) => (value as num?)?.toInt();

  // ====================================================
  // Enum 변환 메서드 (dynamic 입력을 안전하게 String으로 체크 후 변환)
  // ====================================================

  /// BodyPart Enum 변환 (fromJson)
  /// String이 아니면 null 반환 (안전 처리)
  static BodyPart? bodyPartFromCode(dynamic value) {
    if (value is String) {
      return BodyPartParsing.fromCode(value);
    }
    return null; // String이 아니면 null 반환 (안전 처리)
  }

  /// BodyPart Enum 변환 (toJson)
  static String? bodyPartToCode(BodyPart? val) => val?.code;

  /// RpeLevel Enum 변환 (fromJson)
  /// String이 아니면 null 반환 (안전 처리)
  static RpeLevel? rpeLevelFromCode(dynamic value) {
    if (value is String) {
      return RpeLevelParsing.fromCode(value);
    }
    return null; // String이 아니면 null 반환 (안전 처리)
  }

  /// RpeLevel Enum 변환 (toJson)
  static String? rpeLevelToCode(RpeLevel? val) => val?.code;
}

