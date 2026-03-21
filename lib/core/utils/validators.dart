import 'package:flutter/services.dart';

// 허용 문자: 유니코드 문자(글자·숫자)·공백·하이픈·괄호만 허용.
// 제어 문자, RTLO(U+202E) 등 유니코드 방향 지정자, 기타 특수기호를 차단합니다.
final _exerciseNamePattern =
    RegExp(r'^[\p{L}\p{N}\s\-\(\)]+$', unicode: true);

/// 운동 입력값 검증 유틸리티
///
/// 무게, 횟수 등의 입력값 검증과 제한을 담당합니다.
/// 모든 운동 관련 입력 검증은 이 클래스를 통해 처리해야 합니다.
class WorkoutValidators {
  // ============================================
  // 입력 제한 상수
  // ============================================

  /// 운동 이름 최대 길이
  static const int exerciseNameMaxLength = 50;

  /// 최대 무게 (kg)
  static const double maxWeight = 999.0;

  /// 최대 횟수
  static const int maxReps = 999;

  /// 무게 입력 최대 길이 (999.99 형태)
  static const int weightInputMaxLength = 6;

  /// 횟수 입력 최대 길이 (999 형태)
  static const int repsInputMaxLength = 3;

  // ============================================
  // 입력 검증 메서드
  // ============================================

  /// 운동 이름 입력값 검증
  ///
  /// [name] 입력된 운동 이름
  /// 반환: 유효하면 null, 아니면 에러 메시지
  static String? validateExerciseName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '운동 이름을 입력해주세요.';
    }
    if (name.length > exerciseNameMaxLength) {
      return '운동 이름은 $exerciseNameMaxLength자를 초과할 수 없습니다.';
    }
    // 제어 문자·특수기호 차단 (허용: 글자, 숫자, 공백, 하이픈, 괄호)
    if (!_exerciseNamePattern.hasMatch(name.trim())) {
      return '특수문자는 사용할 수 없습니다.';
    }
    return null;
  }

  /// 무게 입력값 검증
  ///
  /// [weight] 입력된 무게 값
  /// 반환: 유효하면 null, 아니면 에러 메시지
  static String? validateWeight(double? weight) {
    if (weight == null) return null;
    if (weight > maxWeight) {
      return '무게는 ${maxWeight.toInt()}kg를 초과할 수 없습니다.';
    }
    if (weight < 0) {
      return '무게는 0보다 작을 수 없습니다.';
    }
    return null;
  }

  /// 횟수 입력값 검증
  ///
  /// [reps] 입력된 횟수 값
  /// 반환: 유효하면 null, 아니면 에러 메시지
  static String? validateReps(int? reps) {
    if (reps == null) return null;
    if (reps > maxReps) {
      return '횟수는 $maxReps회를 초과할 수 없습니다.';
    }
    if (reps < 0) {
      return '횟수는 0보다 작을 수 없습니다.';
    }
    return null;
  }

  /// 무게와 횟수 모두 검증
  ///
  /// 반환: 유효하면 null, 아니면 에러 메시지
  static String? validateWeightAndReps(double? weight, int? reps) {
    final weightError = validateWeight(weight);
    if (weightError != null) return weightError;

    final repsError = validateReps(reps);
    if (repsError != null) return repsError;

    return null;
  }

  /// 무게 값이 유효 범위 내인지 확인
  static bool isWeightValid(double weight) {
    return weight >= 0 && weight <= maxWeight;
  }

  /// 횟수 값이 유효 범위 내인지 확인
  static bool isRepsValid(int reps) {
    return reps >= 0 && reps <= maxReps;
  }

  // ============================================
  // TextInputFormatter 제공
  // ============================================

  /// 무게 입력 필드용 포맷터 목록
  ///
  /// 숫자와 소수점만 허용, 최대 6자리 (999.99)
  static List<TextInputFormatter> get weightInputFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
    LengthLimitingTextInputFormatter(weightInputMaxLength),
  ];

  /// 횟수 입력 필드용 포맷터 목록
  ///
  /// 정수만 허용, 최대 3자리 (999)
  static List<TextInputFormatter> get repsInputFormatters => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(repsInputMaxLength),
  ];

  /// 운동 이름 입력 필드용 포맷터 목록
  ///
  /// 최대 50자
  static List<TextInputFormatter> get exerciseNameInputFormatters => [
    LengthLimitingTextInputFormatter(exerciseNameMaxLength),
  ];
}
