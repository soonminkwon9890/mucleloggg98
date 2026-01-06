// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_baseline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseBaselineImpl _$$ExerciseBaselineImplFromJson(
        Map<String, dynamic> json) =>
    _$ExerciseBaselineImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      exerciseName: json['exerciseName'] as String,
      targetMuscle: json['targetMuscle'] as String?,
      bodyPart: json['bodyPart'] as String?,
      movementType: json['movementType'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      skeletonData: json['skeletonData'] as Map<String, dynamic>?,
      feedbackPrompt: json['feedbackPrompt'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ExerciseBaselineImplToJson(
        _$ExerciseBaselineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'exerciseName': instance.exerciseName,
      'targetMuscle': instance.targetMuscle,
      'bodyPart': instance.bodyPart,
      'movementType': instance.movementType,
      'videoUrl': instance.videoUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'skeletonData': instance.skeletonData,
      'feedbackPrompt': instance.feedbackPrompt,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
