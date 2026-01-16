// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      id: json['id'] as String,
      baselineId: json['baseline_id'] as String,
      weight: JsonConverters.toDouble(json['weight']),
      reps: JsonConverters.toInt(json['reps']),
      sets: json['sets'] == null ? 1 : JsonConverters.toInt(json['sets']),
      rpe: JsonConverters.toIntNullable(json['rpe']),
      rpeLevel: JsonConverters.rpeLevelFromCode(json['rpe_level']),
      estimated1rm: JsonConverters.toDoubleNullable(json['estimated_1rm']),
      isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
      performanceScore:
          JsonConverters.toDoubleNullable(json['performance_score']),
      isCompleted: json['is_completed'] as bool? ?? false,
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
      'rpe_level': JsonConverters.rpeLevelToCode(instance.rpeLevel),
      'estimated_1rm': instance.estimated1rm,
      'is_ai_suggested': instance.isAiSuggested,
      'performance_score': instance.performanceScore,
      'is_completed': instance.isCompleted,
      'created_at': instance.createdAt?.toIso8601String(),
    };
