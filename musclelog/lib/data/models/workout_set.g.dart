// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      id: json['id'] as String,
      baselineId: json['baseline_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      sets: (json['sets'] as num?)?.toInt() ?? 1,
      rpe: (json['rpe'] as num?)?.toInt(),
      rpeLevel: json['rpe_level'] as String?,
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
      performanceScore: (json['performance_score'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$WorkoutSetImplToJson(_$WorkoutSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'baseline_id': instance.baselineId,
      'weight': instance.weight,
      'reps': instance.reps,
      'sets': instance.sets,
      'rpe': instance.rpe,
      'rpe_level': instance.rpeLevel,
      'estimated_1rm': instance.estimated1rm,
      'is_ai_suggested': instance.isAiSuggested,
      'performance_score': instance.performanceScore,
      'created_at': instance.createdAt?.toIso8601String(),
    };
