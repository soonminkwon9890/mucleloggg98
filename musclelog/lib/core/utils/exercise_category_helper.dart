import '../constants/app_constants.dart';

/// 운동 분류 한글-영문 변환 유틸리티
class ExerciseCategoryHelper {
  /// 한글 부위명을 영문 코드로 변환
  /// 
  /// - '상체' -> 'UPPER'
  /// - '하체' -> 'LOWER'
  /// - '전신' -> 'FULL'
  /// 매칭되지 않으면 `null` 반환
  static String? getBodyPartFromKorean(String korean) {
    switch (korean) {
      case '상체':
        return AppConstants.bodyPartUpper;
      case '하체':
        return AppConstants.bodyPartLower;
      case '전신':
        return AppConstants.bodyPartFull;
      default:
        return null;
    }
  }

  /// 한글 운동 타입을 영문 코드로 변환
  /// 
  /// - '밀기' -> 'PUSH'
  /// - '당기기' -> 'PULL'
  /// 매칭되지 않으면 `null` 반환
  static String? getMovementTypeFromKorean(String korean) {
    switch (korean) {
      case '밀기':
        return AppConstants.movementTypePush;
      case '당기기':
        return AppConstants.movementTypePull;
      default:
        return null;
    }
  }

  /// 영문 부위 코드를 한글로 변환
  /// 
  /// - 'UPPER' -> '상체'
  /// - 'LOWER' -> '하체'
  /// - 'FULL' -> '전신'
  /// `null`이거나 매칭되지 않으면 빈 문자열 반환
  static String getKoreanFromBodyPart(String? bodyPart) {
    if (bodyPart == null) return '';
    
    switch (bodyPart) {
      case AppConstants.bodyPartUpper:
        return '상체';
      case AppConstants.bodyPartLower:
        return '하체';
      case AppConstants.bodyPartFull:
        return '전신';
      default:
        return '';
    }
  }

  /// 영문 운동 타입 코드를 한글로 변환
  /// 
  /// - 'PUSH' -> '밀기'
  /// - 'PULL' -> '당기기'
  /// `null`이거나 매칭되지 않으면 빈 문자열 반환
  static String getKoreanFromMovementType(String? movementType) {
    if (movementType == null) return '';
    
    switch (movementType) {
      case AppConstants.movementTypePush:
        return '밀기';
      case AppConstants.movementTypePull:
        return '당기기';
      default:
        return '';
    }
  }
}

