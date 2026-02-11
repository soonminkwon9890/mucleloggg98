import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_point.freezed.dart';
part 'check_point.g.dart';

/// 중간 점검 데이터 모델
@freezed
class CheckPoint with _$CheckPoint {
  const factory CheckPoint({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'baseline_id') required String baselineId,
    @JsonKey(name: 'video_url') required String videoUrl, // 중간 검사 영상 URL
    @JsonKey(name: 'analysis_result')
    String? analysisResult, // AI 분석 결과 (JSON 형태 or 텍스트)
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CheckPoint;

  factory CheckPoint.fromJson(Map<String, dynamic> json) =>
      _$CheckPointFromJson(json);
}
