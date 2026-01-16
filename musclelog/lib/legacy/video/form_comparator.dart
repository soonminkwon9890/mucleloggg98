// Legacy: 추후 고도화 시 참고용
/*
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 순수 생체역학 분석기
/// 운동 종목에 의존하지 않고 관절 각도와 대칭성을 분석합니다.
class BiomechanicsAnalyzer {
  /// 세 점으로 이루어진 관절 각도 계산
  ///
  /// [first] 첫 번째 랜드마크 (관절의 시작점)
  /// [mid] 중간 랜드마크 (관절의 중심점, 각도가 계산되는 지점)
  /// [last] 마지막 랜드마크 (관절의 끝점)
  ///
  /// 반환: 관절 각도 (0° ~ 180°), 랜드마크가 null이면 -1 반환
  static double _calculateAngle(
    PoseLandmark? first,
    PoseLandmark? mid,
    PoseLandmark? last,
  ) {
    // null 체크: 랜드마크가 없으면 -1 반환
    if (first == null || mid == null || last == null) {
      return -1.0;
    }

    // 벡터 계산: mid를 기준으로 first와 last까지의 벡터
    final vector1 = (
      x: first.x - mid.x,
      y: first.y - mid.y,
    );
    final vector2 = (
      x: last.x - mid.x,
      y: last.y - mid.y,
    );

    // 벡터의 크기 계산
    final magnitude1 = math.sqrt(vector1.x * vector1.x + vector1.y * vector1.y);
    final magnitude2 = math.sqrt(vector2.x * vector2.x + vector2.y * vector2.y);

    // 벡터 크기가 0이면 각도 계산 불가
    if (magnitude1 == 0 || magnitude2 == 0) {
      return -1.0;
    }

    // 내적 계산
    final dotProduct = vector1.x * vector2.x + vector1.y * vector2.y;

    // 코사인 값 계산 (정규화)
    final cosAngle = dotProduct / (magnitude1 * magnitude2);

    // 각도 계산 (라디안 → 도)
    // clamp를 사용하여 -1 ~ 1 범위로 제한 (부동소수점 오차 방지)
    final angleRadians = math.acos(cosAngle.clamp(-1.0, 1.0));
    final angleDegrees = angleRadians * 180 / math.pi;

    return angleDegrees;
  }

  /// 포즈의 생체역학 분석
  ///
  /// [pose] ML Kit에서 감지된 포즈 객체
  ///
  /// 반환: 관절 각도와 대칭성 정보를 포함한 맵
  static Map<String, dynamic> analyzeMechanics(Pose pose) {
    final landmarks = pose.landmarks;
    final joints = <String, double>{};
    final symmetry = <String, double>{};

    // 1. 팔꿈치 각도 (Elbow Angle)
    // 왼쪽: 어깨 -> 팔꿈치 -> 손목
    final leftElbow = _calculateAngle(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
      landmarks[PoseLandmarkType.leftWrist],
    );
    joints['left_elbow'] = leftElbow;

    // 오른쪽: 어깨 -> 팔꿈치 -> 손목
    final rightElbow = _calculateAngle(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
      landmarks[PoseLandmarkType.rightWrist],
    );
    joints['right_elbow'] = rightElbow;

    // 팔꿈치 대칭성 계산
    if (leftElbow > 0 && rightElbow > 0) {
      symmetry['elbow_diff'] = (leftElbow - rightElbow).abs();
    }

    // 2. 어깨 각도 (Shoulder Angle) - 팔의 상승/밀기 동작 측정
    // 왼쪽: 엉덩이 -> 어깨 -> 팔꿈치
    final leftShoulder = _calculateAngle(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
    );
    joints['left_shoulder'] = leftShoulder;

    // 오른쪽: 엉덩이 -> 어깨 -> 팔꿈치
    final rightShoulder = _calculateAngle(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
    );
    joints['right_shoulder'] = rightShoulder;

    // 어깨 대칭성 계산
    if (leftShoulder > 0 && rightShoulder > 0) {
      symmetry['shoulder_diff'] = (leftShoulder - rightShoulder).abs();
    }

    // 3. 엉덩이 각도 (Hip Angle / Torso Angle) - 전방 기울기/힙 힌지 측정
    // 왼쪽: 어깨 -> 엉덩이 -> 무릎
    final leftHip = _calculateAngle(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
    );
    joints['left_hip'] = leftHip;

    // 오른쪽: 어깨 -> 엉덩이 -> 무릎
    final rightHip = _calculateAngle(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
    );
    joints['right_hip'] = rightHip;

    // 엉덩이 대칭성 계산
    if (leftHip > 0 && rightHip > 0) {
      symmetry['hip_diff'] = (leftHip - rightHip).abs();
    }

    // 4. 무릎 각도 (Knee Angle) - 다리 굴곡/스쿼트 깊이 측정
    // 왼쪽: 엉덩이 -> 무릎 -> 발목
    final leftKnee = _calculateAngle(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
    );
    joints['left_knee'] = leftKnee;

    // 오른쪽: 엉덩이 -> 무릎 -> 발목
    final rightKnee = _calculateAngle(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
    );
    joints['right_knee'] = rightKnee;

    // 무릎 대칭성 계산
    if (leftKnee > 0 && rightKnee > 0) {
      symmetry['knee_diff'] = (leftKnee - rightKnee).abs();
    }

    return {
      'joints': joints,
      'symmetry': symmetry,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 두 포즈 데이터 비교 (기준 포즈와 현재 포즈)
  ///
  /// [baselinePose] 기준 포즈 데이터 (skeleton_data JSON 형식)
  /// [currentPose] 현재 포즈 객체 (ML Kit Pose)
  ///
  /// 반환: 비교 결과 (ROM 변화율 등)
  static Map<String, dynamic> comparePoses(
    Map<String, dynamic> baselinePose,
    Pose currentPose,
  ) {
    // 현재 포즈 분석
    final currentMechanics = analyzeMechanics(currentPose);
    final currentJoints = currentMechanics['joints'] as Map<String, double>;

    // 기준 포즈에서 관절 각도 추출 (JSON 형식)
    // baselinePose는 JSON 형식이므로 직접 비교하기 어려움
    // 추후 기준 포즈도 Pose 객체로 변환하거나 각도를 저장하는 방식으로 개선 필요

    // 현재는 기본 비교 결과만 반환
    final romChanges = <String, double>{};
    final feedback = <String>[];

    // 각 관절별로 변화 분석 (기준 데이터가 있으면 비교)
    for (final entry in currentJoints.entries) {
      final jointName = entry.key;
      final currentAngle = entry.value;

      if (currentAngle < 0) {
        // 랜드마크가 감지되지 않음
        continue;
      }

      // 대칭성 체크
      if (jointName.contains('left_') || jointName.contains('right_')) {
        final symmetryKey =
            '${jointName.replaceAll('left_', '').replaceAll('right_', '')}_diff';
        final symmetry = currentMechanics['symmetry'] as Map<String, double>;
        final diff = symmetry[symmetryKey];

        if (diff != null && diff > 10) {
          // 좌우 차이가 10도 이상이면 불균형 경고
          feedback.add(
              '$jointName의 좌우 불균형이 감지되었습니다 (차이: ${diff.toStringAsFixed(1)}도)');
        }
      }
    }

    return {
      'rom_change': romChanges,
      'symmetry': currentMechanics['symmetry'],
      'joints': currentJoints,
      'feedback': feedback.isEmpty ? ['자세가 기준과 유사합니다.'] : feedback,
      'timestamp': currentMechanics['timestamp'],
    };
  }
}
*/
