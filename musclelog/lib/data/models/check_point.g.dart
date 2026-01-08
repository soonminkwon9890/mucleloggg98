// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckPointImpl _$$CheckPointImplFromJson(Map<String, dynamic> json) =>
    _$CheckPointImpl(
      id: json['id'] as String,
      baselineId: json['baseline_id'] as String,
      checkVideoPath: json['check_video_path'] as String,
      comparisonResult: json['comparison_result'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CheckPointImplToJson(_$CheckPointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baseline_id': instance.baselineId,
      'check_video_path': instance.checkVideoPath,
      'comparison_result': instance.comparisonResult,
      'created_at': instance.createdAt?.toIso8601String(),
    };
