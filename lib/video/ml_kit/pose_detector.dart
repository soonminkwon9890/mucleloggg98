// TODO: [AI Pivot] 나중에 AI 기능 복구 시 주석 해제
/*
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_compress/video_compress.dart';

/// ML Kit Pose Detection 서비스
class PoseDetectionService {
  late final PoseDetector _poseDetector;

  PoseDetectionService() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  /// 비디오 파일에서 대표 프레임을 추출하여 포즈 분석 (기준 자세 설정용)
  /// 
  /// [videoFile] 비디오 파일
  /// 
  /// 반환: 감지된 포즈 리스트
  Future<List<Pose>> detectPoseFromVideo(File videoFile) async {
    try {
      // 1. 비디오에서 고화질 썸네일(대표 프레임) 추출
      final File thumbnail = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 100, // 분석용이므로 최고 화질
        position: -1, // 영상의 중간 지점 (또는 필요시 조정)
      );

      // 2. 추출된 이미지로 포즈 감지 실행
      final inputImage = InputImage.fromFilePath(thumbnail.path);
      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      return poses;
    } catch (e) {
      throw Exception('비디오 포즈 분석 실패: $e');
    }
  }

  /// 영상 파일에서 가장 완벽한 자세 프레임의 관절 좌표 추출
  /// 
  /// [videoPath] 영상 파일 경로
  /// 
  /// 반환: 관절 좌표 데이터 (JSON 형식)
  Future<Map<String, dynamic>?> extractSkeletonData(String videoPath) async {
    try {
      final videoFile = File(videoPath);
      final poses = await detectPoseFromVideo(videoFile);

      if (poses.isEmpty) {
        return null;
      }

      // 첫 번째 포즈 선택 (가장 확신도가 높은 포즈)
      final bestPose = poses.first;

      // 관절 좌표를 JSON 형식으로 변환
      final skeletonData = <String, dynamic>{};
      
      for (final landmark in bestPose.landmarks.values) {
        final landmarkType = landmark.type.toString().split('.').last;
        skeletonData[landmarkType] = {
          'x': landmark.x,
          'y': landmark.y,
          'z': landmark.z,
        };
      }

      return skeletonData;
    } catch (e) {
      throw Exception('스켈레톤 데이터 추출 실패: $e');
    }
  }

  /// 이미지에서 관절 좌표 추출
  /// 
  /// [imageFile] 이미지 파일
  /// 
  /// 반환: 관절 좌표 데이터 (JSON 형식)
  Future<Map<String, dynamic>?> extractPoseFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return null;
      }

      // 첫 번째 포즈 선택 (가장 확신도가 높은 포즈)
      final bestPose = poses.first;

      // 관절 좌표를 JSON 형식으로 변환
      final skeletonData = <String, dynamic>{};
      
      for (final landmark in bestPose.landmarks.values) {
        final landmarkType = landmark.type.toString().split('.').last;
        skeletonData[landmarkType] = {
          'x': landmark.x,
          'y': landmark.y,
          'z': landmark.z,
        };
      }

      return skeletonData;
    } catch (e) {
      throw Exception('포즈 감지 중 오류가 발생했습니다: $e');
    }
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
*/
