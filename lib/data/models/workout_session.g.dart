// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      baselineId: json['baseline_id'] as String,
      workoutDate: DateTime.parse(json['workout_date'] as String),
      difficulty: json['difficulty'] as String,
      totalVolume: JsonConverters.toDoubleNullable(json['total_volume']),
      durationMinutes: JsonConverters.toIntNullable(json['duration_minutes']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'baseline_id': instance.baselineId,
      'workout_date': instance.workoutDate.toIso8601String(),
      'difficulty': instance.difficulty,
      'total_volume': instance.totalVolume,
      'duration_minutes': instance.durationMinutes,
      'created_at': instance.createdAt?.toIso8601String(),
    };
