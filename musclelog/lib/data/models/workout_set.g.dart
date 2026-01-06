// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      id: json['id'] as String,
      baselineId: json['baselineId'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      rpe: (json['rpe'] as num?)?.toInt(),
      rpeLevel: json['rpeLevel'] as String?,
      estimated1rm: (json['estimated1rm'] as num?)?.toDouble(),
      isAiSuggested: json['isAiSuggested'] as bool? ?? false,
      performanceScore: (json['performanceScore'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WorkoutSetImplToJson(_$WorkoutSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baselineId': instance.baselineId,
      'weight': instance.weight,
      'reps': instance.reps,
      'rpe': instance.rpe,
      'rpeLevel': instance.rpeLevel,
      'estimated1rm': instance.estimated1rm,
      'isAiSuggested': instance.isAiSuggested,
      'performanceScore': instance.performanceScore,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
