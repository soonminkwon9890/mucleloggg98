import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_point.freezed.dart';
part 'check_point.g.dart';

/// 중간 점검 데이터 모델
@freezed
class CheckPoint with _$CheckPoint {
  const factory CheckPoint({
    required String id,
    required String baselineId,
    required String checkVideoPath, // 중간 점검 영상 경로
    Map<String, dynamic>? comparisonResult, // JSONB: { "rom_change": -10, "muscle_activation_change": +15... }
    DateTime? createdAt,
  }) = _CheckPoint;

  factory CheckPoint.fromJson(Map<String, dynamic> json) =>
      _$CheckPointFromJson(json);
}

