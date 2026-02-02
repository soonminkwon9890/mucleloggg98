// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlannedWorkoutImpl _$$PlannedWorkoutImplFromJson(Map<String, dynamic> json) =>
    _$PlannedWorkoutImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      baselineId: json['baseline_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      targetWeight: JsonConverters.toDouble(json['target_weight']),
      targetReps: JsonConverters.toInt(json['target_reps']),
      targetSets: json['target_sets'] == null
          ? 3
          : JsonConverters.toInt(json['target_sets']),
      aiComment: json['ai_comment'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      exerciseName: json['exercise_name'] as String?,
      isConvertedToLog: json['is_converted_to_log'] as bool? ?? false,
      colorHex: json['color_hex'] as String? ?? '0xFF2196F3',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$PlannedWorkoutImplToJson(
        _$PlannedWorkoutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'baseline_id': instance.baselineId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'target_weight': instance.targetWeight,
      'target_reps': instance.targetReps,
      'target_sets': instance.targetSets,
      'ai_comment': instance.aiComment,
      'is_completed': instance.isCompleted,
      'exercise_name': instance.exerciseName,
      'is_converted_to_log': instance.isConvertedToLog,
      'color_hex': instance.colorHex,
      'created_at': instance.createdAt?.toIso8601String(),
    };
