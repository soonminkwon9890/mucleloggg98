/// 앱 전역 상수 정의
class AppConstants {
  // 앱 정보
  static const String appName = 'MuscleLog';
  static const String appVersion = '1.0.0';

  // 운동 경력 레벨
  static const String experienceBeginner = 'BEGINNER';
  static const String experienceIntermediate = 'INTERMEDIATE';
  static const String experienceAdvanced = 'ADVANCED';

  // 신체 부위
  static const String bodyPartUpper = 'UPPER';
  static const String bodyPartLower = 'LOWER';
  static const String bodyPartFull = 'FULL';

  // 운동 타입
  static const String movementTypePush = 'PUSH';
  static const String movementTypePull = 'PULL';

  // RPE 레벨
  static const String rpeLevelLow = 'LOW';
  static const String rpeLevelMedium = 'MEDIUM';
  static const String rpeLevelHigh = 'HIGH';

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

