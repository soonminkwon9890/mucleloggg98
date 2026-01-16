// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckPointImpl _$$CheckPointImplFromJson(Map<String, dynamic> json) =>
    _$CheckPointImpl(
      id: json['id'] as String,
      baselineId: json['baseline_id'] as String,
      videoUrl: json['video_url'] as String,
      analysisResult: json['analysis_result'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CheckPointImplToJson(_$CheckPointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baseline_id': instance.baselineId,
      'video_url': instance.videoUrl,
      'analysis_result': instance.analysisResult,
      'created_at': instance.createdAt?.toIso8601String(),
    };
