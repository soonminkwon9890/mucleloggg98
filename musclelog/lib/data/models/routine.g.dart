// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoutineImpl _$$RoutineImplFromJson(Map<String, dynamic> json) =>
    _$RoutineImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      routineItems: (json['routine_items'] as List<dynamic>?)
          ?.map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$RoutineImplToJson(_$RoutineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'created_at': instance.createdAt?.toIso8601String(),
    };
