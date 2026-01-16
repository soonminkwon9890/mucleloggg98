import 'dart:io';
import 'package:video_compress/video_compress.dart';

/// 영상 압축 유틸리티
class VideoCompressor {
  /// 영상 압축
  /// 
  /// [file] 압축할 영상 파일
  /// 
  /// 반환: 압축된 영상 정보
  Future<MediaInfo?> compressVideo(File file) async {
    try {
      await VideoCompress.setLogLevel(0);
      return await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
    } catch (e) {
      throw Exception('Video compression failed: $e');
    }
  }

  /// 영상의 첫 프레임을 이미지로 추출 (썸네일 생성)
  /// 
  /// [file] 영상 파일
  /// 
  /// 반환: 썸네일 이미지 파일
  Future<File> generateThumbnail(File file) async {
    try {
      final File thumbnail = await VideoCompress.getFileThumbnail(
        file.path,
        quality: 50,
        position: -1,
      );
      return thumbnail;
    } catch (e) {
      throw Exception('Thumbnail generation failed: $e');
    }
  }

  /// 영상 정보 가져오기
  Future<MediaInfo?> getVideoInfo(String videoPath) async {
    try {
      return await VideoCompress.getMediaInfo(videoPath);
    } catch (e) {
      throw Exception('영상 정보를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 리소스 정리
  Future<void> clearCache() async {
    await VideoCompress.deleteAllCache();
  }
}

