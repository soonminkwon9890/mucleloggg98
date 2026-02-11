/// 앱 전역 상수 정의
class AppConstants {
  // 앱 정보
  static const String appName = 'MuscleLog';
  static const String appVersion = '1.0.0';

  // 운동 경력 레벨
  static const String experienceBeginner = 'BEGINNER';
  static const String experienceIntermediate = 'INTERMEDIATE';
  static const String experienceAdvanced = 'ADVANCED';

  // [Phase 1.2] BodyPart, MovementType, RpeLevel 관련 상수는 Enum으로 대체됨
  // enum BodyPart, MovementType, RpeLevel 사용 (lib/core/enums/exercise_enums.dart)

  // RPE 범위
  static const int rpeMin = 1;
  static const int rpeMax = 10;
  static const int rpeLowThreshold = 4;
  static const int rpeMediumThreshold = 7;

  // Storage 버킷 이름
  static const String storageBucketVideos = 'videos';

  // 파일 확장자
  static const String videoExtension = '.mp4';
  static const String imageExtension = '.jpg';
}

