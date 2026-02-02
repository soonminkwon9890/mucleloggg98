import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 미디어 소스 선택 및 파일 가져오기 유틸리티
/// 
/// ⚠️ iOS 시뮬레이터 주의사항:
/// - 카메라 기능은 iOS 시뮬레이터에서 작동하지 않습니다.
/// - ML Kit Pose Detection 테스트 시 반드시 실기기를 사용하세요.
/// - 갤러리 선택 기능은 시뮬레이터에서도 정상 작동합니다.
class MediaHelper {
  static final ImagePicker _picker = ImagePicker();

  /// 카메라로 비디오 촬영
  /// 
  /// ⚠️ 주의: iOS 시뮬레이터에서는 카메라가 작동하지 않습니다.
  /// 테스트 시 반드시 실기기를 사용하세요.
  static Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      throw Exception('카메라로 비디오를 촬영하는 중 오류가 발생했습니다: $e');
    }
  }

  /// 갤러리에서 비디오 선택
  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      throw Exception('갤러리에서 비디오를 선택하는 중 오류가 발생했습니다: $e');
    }
  }

  /// 이미지 선택 (썸네일용)
  /// 
  /// [fromCamera]가 true인 경우 카메라로 촬영합니다.
  /// ⚠️ 주의: iOS 시뮬레이터에서는 카메라가 작동하지 않습니다.
  static Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('이미지를 선택하는 중 오류가 발생했습니다: $e');
    }
  }
}

