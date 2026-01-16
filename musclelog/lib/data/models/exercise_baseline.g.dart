// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_baseline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseBaselineImpl _$$ExerciseBaselineImplFromJson(
        Map<String, dynamic> json) =>
    _$ExerciseBaselineImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseName: json['exercise_name'] as String,
      targetMuscle: json['target_muscle'] as String?,
      bodyPart: JsonConverters.bodyPartFromCode(json['body_part']),
      movementType: JsonConverters.movementTypeFromCode(json['movement_type']),
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      skeletonData: json['skeleton_data'] as Map<String, dynamic>?,
      feedbackPrompt: json['feedback_prompt'] as String?,
      workoutSets: (json['workout_sets'] as List<dynamic>?)
          ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      routineId: json['routine_id'] as String?,
      isHiddenFromHome: json['is_hidden_from_home'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ExerciseBaselineImplToJson(
        _$ExerciseBaselineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'exercise_name': instance.exerciseName,
      'target_muscle': instance.targetMuscle,
      'body_part': JsonConverters.bodyPartToCode(instance.bodyPart),
      'movement_type': JsonConverters.movementTypeToCode(instance.movementType),
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'skeleton_data': instance.skeletonData,
      'feedback_prompt': instance.feedbackPrompt,
      'routine_id': instance.routineId,
      'is_hidden_from_home': instance.isHiddenFromHome,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
