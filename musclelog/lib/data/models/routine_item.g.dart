// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoutineItemImpl _$$RoutineItemImplFromJson(Map<String, dynamic> json) =>
    _$RoutineItemImpl(
      id: json['id'] as String,
      routineId: json['routine_id'] as String,
      exerciseName: json['exercise_name'] as String,
      bodyPart: JsonConverters.bodyPartFromCode(json['body_part']),
      movementType: JsonConverters.movementTypeFromCode(json['movement_type']),
      sortOrder: json['sort_order'] == null
          ? 0
          : JsonConverters.toInt(json['sort_order']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$RoutineItemImplToJson(_$RoutineItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'routine_id': instance.routineId,
      'exercise_name': instance.exerciseName,
      'body_part': JsonConverters.bodyPartToCode(instance.bodyPart),
      'movement_type': JsonConverters.movementTypeToCode(instance.movementType),
      'sort_order': instance.sortOrder,
      'created_at': instance.createdAt?.toIso8601String(),
    };
