// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planned_workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlannedWorkout _$PlannedWorkoutFromJson(Map<String, dynamic> json) {
  return _PlannedWorkout.fromJson(json);
}

/// @nodoc
mixin _$PlannedWorkout {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'baseline_id')
  String get baselineId => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheduled_date')
  DateTime get scheduledDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
  double get targetWeight => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
  int get targetReps => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
  int get targetSets => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_comment')
  String? get aiComment => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise_name')
  String? get exerciseName =>
      throw _privateConstructorUsedError; // 운동 이름 (디노멀라이제이션)
  @JsonKey(name: 'is_converted_to_log')
  bool get isConvertedToLog =>
      throw _privateConstructorUsedError; // 이미 WorkoutSet으로 변환되었는지 여부
  @JsonKey(name: 'color_hex')
  String get colorHex => throw _privateConstructorUsedError; // 캘린더 색상
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PlannedWorkout to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlannedWorkout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlannedWorkoutCopyWith<PlannedWorkout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlannedWorkoutCopyWith<$Res> {
  factory $PlannedWorkoutCopyWith(
          PlannedWorkout value, $Res Function(PlannedWorkout) then) =
      _$PlannedWorkoutCopyWithImpl<$Res, PlannedWorkout>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'baseline_id') String baselineId,
      @JsonKey(name: 'scheduled_date') DateTime scheduledDate,
      @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
      double targetWeight,
      @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
      int targetReps,
      @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
      int targetSets,
      @JsonKey(name: 'ai_comment') String? aiComment,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'exercise_name') String? exerciseName,
      @JsonKey(name: 'is_converted_to_log') bool isConvertedToLog,
      @JsonKey(name: 'color_hex') String colorHex,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$PlannedWorkoutCopyWithImpl<$Res, $Val extends PlannedWorkout>
    implements $PlannedWorkoutCopyWith<$Res> {
  _$PlannedWorkoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlannedWorkout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? baselineId = null,
    Object? scheduledDate = null,
    Object? targetWeight = null,
    Object? targetReps = null,
    Object? targetSets = null,
    Object? aiComment = freezed,
    Object? isCompleted = null,
    Object? exerciseName = freezed,
    Object? isConvertedToLog = null,
    Object? colorHex = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      baselineId: null == baselineId
          ? _value.baselineId
          : baselineId // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDate: null == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      targetWeight: null == targetWeight
          ? _value.targetWeight
          : targetWeight // ignore: cast_nullable_to_non_nullable
              as double,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as int,
      targetSets: null == targetSets
          ? _value.targetSets
          : targetSets // ignore: cast_nullable_to_non_nullable
              as int,
      aiComment: freezed == aiComment
          ? _value.aiComment
          : aiComment // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseName: freezed == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String?,
      isConvertedToLog: null == isConvertedToLog
          ? _value.isConvertedToLog
          : isConvertedToLog // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlannedWorkoutImplCopyWith<$Res>
    implements $PlannedWorkoutCopyWith<$Res> {
  factory _$$PlannedWorkoutImplCopyWith(_$PlannedWorkoutImpl value,
          $Res Function(_$PlannedWorkoutImpl) then) =
      __$$PlannedWorkoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'baseline_id') String baselineId,
      @JsonKey(name: 'scheduled_date') DateTime scheduledDate,
      @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
      double targetWeight,
      @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
      int targetReps,
      @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
      int targetSets,
      @JsonKey(name: 'ai_comment') String? aiComment,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'exercise_name') String? exerciseName,
      @JsonKey(name: 'is_converted_to_log') bool isConvertedToLog,
      @JsonKey(name: 'color_hex') String colorHex,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$PlannedWorkoutImplCopyWithImpl<$Res>
    extends _$PlannedWorkoutCopyWithImpl<$Res, _$PlannedWorkoutImpl>
    implements _$$PlannedWorkoutImplCopyWith<$Res> {
  __$$PlannedWorkoutImplCopyWithImpl(
      _$PlannedWorkoutImpl _value, $Res Function(_$PlannedWorkoutImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlannedWorkout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? baselineId = null,
    Object? scheduledDate = null,
    Object? targetWeight = null,
    Object? targetReps = null,
    Object? targetSets = null,
    Object? aiComment = freezed,
    Object? isCompleted = null,
    Object? exerciseName = freezed,
    Object? isConvertedToLog = null,
    Object? colorHex = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$PlannedWorkoutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      baselineId: null == baselineId
          ? _value.baselineId
          : baselineId // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDate: null == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      targetWeight: null == targetWeight
          ? _value.targetWeight
          : targetWeight // ignore: cast_nullable_to_non_nullable
              as double,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as int,
      targetSets: null == targetSets
          ? _value.targetSets
          : targetSets // ignore: cast_nullable_to_non_nullable
              as int,
      aiComment: freezed == aiComment
          ? _value.aiComment
          : aiComment // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseName: freezed == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String?,
      isConvertedToLog: null == isConvertedToLog
          ? _value.isConvertedToLog
          : isConvertedToLog // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlannedWorkoutImpl implements _PlannedWorkout {
  const _$PlannedWorkoutImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'baseline_id') required this.baselineId,
      @JsonKey(name: 'scheduled_date') required this.scheduledDate,
      @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
      required this.targetWeight,
      @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
      required this.targetReps,
      @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
      this.targetSets = 3,
      @JsonKey(name: 'ai_comment') this.aiComment,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'exercise_name') this.exerciseName,
      @JsonKey(name: 'is_converted_to_log') this.isConvertedToLog = false,
      @JsonKey(name: 'color_hex') this.colorHex = '0xFF2196F3',
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$PlannedWorkoutImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlannedWorkoutImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'baseline_id')
  final String baselineId;
  @override
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @override
  @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
  final double targetWeight;
  @override
  @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
  final int targetReps;
  @override
  @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
  final int targetSets;
  @override
  @JsonKey(name: 'ai_comment')
  final String? aiComment;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;
// 운동 이름 (디노멀라이제이션)
  @override
  @JsonKey(name: 'is_converted_to_log')
  final bool isConvertedToLog;
// 이미 WorkoutSet으로 변환되었는지 여부
  @override
  @JsonKey(name: 'color_hex')
  final String colorHex;
// 캘린더 색상
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'PlannedWorkout(id: $id, userId: $userId, baselineId: $baselineId, scheduledDate: $scheduledDate, targetWeight: $targetWeight, targetReps: $targetReps, targetSets: $targetSets, aiComment: $aiComment, isCompleted: $isCompleted, exerciseName: $exerciseName, isConvertedToLog: $isConvertedToLog, colorHex: $colorHex, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlannedWorkoutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.baselineId, baselineId) ||
                other.baselineId == baselineId) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.targetWeight, targetWeight) ||
                other.targetWeight == targetWeight) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.targetSets, targetSets) ||
                other.targetSets == targetSets) &&
            (identical(other.aiComment, aiComment) ||
                other.aiComment == aiComment) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.isConvertedToLog, isConvertedToLog) ||
                other.isConvertedToLog == isConvertedToLog) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      baselineId,
      scheduledDate,
      targetWeight,
      targetReps,
      targetSets,
      aiComment,
      isCompleted,
      exerciseName,
      isConvertedToLog,
      colorHex,
      createdAt);

  /// Create a copy of PlannedWorkout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlannedWorkoutImplCopyWith<_$PlannedWorkoutImpl> get copyWith =>
      __$$PlannedWorkoutImplCopyWithImpl<_$PlannedWorkoutImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlannedWorkoutImplToJson(
      this,
    );
  }
}

abstract class _PlannedWorkout implements PlannedWorkout {
  const factory _PlannedWorkout(
      {@JsonKey(name: 'id') required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'baseline_id') required final String baselineId,
      @JsonKey(name: 'scheduled_date') required final DateTime scheduledDate,
      @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
      required final double targetWeight,
      @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
      required final int targetReps,
      @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
      final int targetSets,
      @JsonKey(name: 'ai_comment') final String? aiComment,
      @JsonKey(name: 'is_completed') final bool isCompleted,
      @JsonKey(name: 'exercise_name') final String? exerciseName,
      @JsonKey(name: 'is_converted_to_log') final bool isConvertedToLog,
      @JsonKey(name: 'color_hex') final String colorHex,
      @JsonKey(name: 'created_at')
      final DateTime? createdAt}) = _$PlannedWorkoutImpl;

  factory _PlannedWorkout.fromJson(Map<String, dynamic> json) =
      _$PlannedWorkoutImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'baseline_id')
  String get baselineId;
  @override
  @JsonKey(name: 'scheduled_date')
  DateTime get scheduledDate;
  @override
  @JsonKey(name: 'target_weight', fromJson: JsonConverters.toDouble)
  double get targetWeight;
  @override
  @JsonKey(name: 'target_reps', fromJson: JsonConverters.toInt)
  int get targetReps;
  @override
  @JsonKey(name: 'target_sets', fromJson: JsonConverters.toInt)
  int get targetSets;
  @override
  @JsonKey(name: 'ai_comment')
  String? get aiComment;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'exercise_name')
  String? get exerciseName; // 운동 이름 (디노멀라이제이션)
  @override
  @JsonKey(name: 'is_converted_to_log')
  bool get isConvertedToLog; // 이미 WorkoutSet으로 변환되었는지 여부
  @override
  @JsonKey(name: 'color_hex')
  String get colorHex; // 캘린더 색상
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of PlannedWorkout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlannedWorkoutImplCopyWith<_$PlannedWorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
