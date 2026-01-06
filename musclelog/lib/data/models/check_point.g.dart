// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckPointImpl _$$CheckPointImplFromJson(Map<String, dynamic> json) =>
    _$CheckPointImpl(
      id: json['id'] as String,
      baselineId: json['baselineId'] as String,
      checkVideoPath: json['checkVideoPath'] as String,
      comparisonResult: json['comparisonResult'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CheckPointImplToJson(_$CheckPointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baselineId': instance.baselineId,
      'checkVideoPath': instance.checkVideoPath,
      'comparisonResult': instance.comparisonResult,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
