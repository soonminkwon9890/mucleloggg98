// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_baseline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseBaseline _$ExerciseBaselineFromJson(Map<String, dynamic> json) {
  return _ExerciseBaseline.fromJson(json);
}

/// @nodoc
mixin _$ExerciseBaseline {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise_name')
  String get exerciseName =>
      throw _privateConstructorUsedError; // 'BENCH_PRESS', 'SQUAT' 등
  @JsonKey(name: 'target_muscle')
  String? get targetMuscle =>
      throw _privateConstructorUsedError; // 'CHEST', 'LEGS'
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  BodyPart? get bodyPart =>
      throw _privateConstructorUsedError; // Enum: upper, lower, full
  @JsonKey(
      name: 'movement_type',
      fromJson: JsonConverters.movementTypeFromCode,
      toJson: JsonConverters.movementTypeToCode)
  MovementType? get movementType =>
      throw _privateConstructorUsedError; // Enum: push, pull
  @JsonKey(name: 'video_url')
  String? get videoUrl => throw _privateConstructorUsedError; // 원본/압축 영상 경로
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError; // 리스트 표시용 썸네일
  @JsonKey(name: 'skeleton_data')
  Map<String, dynamic>? get skeletonData =>
      throw _privateConstructorUsedError; // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  @JsonKey(name: 'feedback_prompt')
  String? get feedbackPrompt =>
      throw _privateConstructorUsedError; // "어깨 관절 개입 과다" 등 분석 내용
  @JsonKey(name: 'workout_sets', includeToJson: false)
  List<WorkoutSet>? get workoutSets =>
      throw _privateConstructorUsedError; // 조인 쿼리 결과 매핑용 (읽기 전용)
  @JsonKey(name: 'routine_id')
  String? get routineId => throw _privateConstructorUsedError; // 루틴 실행 이력 추적용
  @JsonKey(name: 'is_hidden_from_home')
  bool get isHiddenFromHome =>
      throw _privateConstructorUsedError; // 홈 화면에서 숨김 여부
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseBaselineCopyWith<ExerciseBaseline> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseBaselineCopyWith<$Res> {
  factory $ExerciseBaselineCopyWith(
          ExerciseBaseline value, $Res Function(ExerciseBaseline) then) =
      _$ExerciseBaselineCopyWithImpl<$Res, ExerciseBaseline>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'exercise_name') String exerciseName,
      @JsonKey(name: 'target_muscle') String? targetMuscle,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      BodyPart? bodyPart,
      @JsonKey(
          name: 'movement_type',
          fromJson: JsonConverters.movementTypeFromCode,
          toJson: JsonConverters.movementTypeToCode)
      MovementType? movementType,
      @JsonKey(name: 'video_url') String? videoUrl,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'skeleton_data') Map<String, dynamic>? skeletonData,
      @JsonKey(name: 'feedback_prompt') String? feedbackPrompt,
      @JsonKey(name: 'workout_sets', includeToJson: false)
      List<WorkoutSet>? workoutSets,
      @JsonKey(name: 'routine_id') String? routineId,
      @JsonKey(name: 'is_hidden_from_home') bool isHiddenFromHome,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ExerciseBaselineCopyWithImpl<$Res, $Val extends ExerciseBaseline>
    implements $ExerciseBaselineCopyWith<$Res> {
  _$ExerciseBaselineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? exerciseName = null,
    Object? targetMuscle = freezed,
    Object? bodyPart = freezed,
    Object? movementType = freezed,
    Object? videoUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? skeletonData = freezed,
    Object? feedbackPrompt = freezed,
    Object? workoutSets = freezed,
    Object? routineId = freezed,
    Object? isHiddenFromHome = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyPart: freezed == bodyPart
          ? _value.bodyPart
          : bodyPart // ignore: cast_nullable_to_non_nullable
              as BodyPart?,
      movementType: freezed == movementType
          ? _value.movementType
          : movementType // ignore: cast_nullable_to_non_nullable
              as MovementType?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      skeletonData: freezed == skeletonData
          ? _value.skeletonData
          : skeletonData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      feedbackPrompt: freezed == feedbackPrompt
          ? _value.feedbackPrompt
          : feedbackPrompt // ignore: cast_nullable_to_non_nullable
              as String?,
      workoutSets: freezed == workoutSets
          ? _value.workoutSets
          : workoutSets // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSet>?,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      isHiddenFromHome: null == isHiddenFromHome
          ? _value.isHiddenFromHome
          : isHiddenFromHome // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseBaselineImplCopyWith<$Res>
    implements $ExerciseBaselineCopyWith<$Res> {
  factory _$$ExerciseBaselineImplCopyWith(_$ExerciseBaselineImpl value,
          $Res Function(_$ExerciseBaselineImpl) then) =
      __$$ExerciseBaselineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'exercise_name') String exerciseName,
      @JsonKey(name: 'target_muscle') String? targetMuscle,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      BodyPart? bodyPart,
      @JsonKey(
          name: 'movement_type',
          fromJson: JsonConverters.movementTypeFromCode,
          toJson: JsonConverters.movementTypeToCode)
      MovementType? movementType,
      @JsonKey(name: 'video_url') String? videoUrl,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'skeleton_data') Map<String, dynamic>? skeletonData,
      @JsonKey(name: 'feedback_prompt') String? feedbackPrompt,
      @JsonKey(name: 'workout_sets', includeToJson: false)
      List<WorkoutSet>? workoutSets,
      @JsonKey(name: 'routine_id') String? routineId,
      @JsonKey(name: 'is_hidden_from_home') bool isHiddenFromHome,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$ExerciseBaselineImplCopyWithImpl<$Res>
    extends _$ExerciseBaselineCopyWithImpl<$Res, _$ExerciseBaselineImpl>
    implements _$$ExerciseBaselineImplCopyWith<$Res> {
  __$$ExerciseBaselineImplCopyWithImpl(_$ExerciseBaselineImpl _value,
      $Res Function(_$ExerciseBaselineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? exerciseName = null,
    Object? targetMuscle = freezed,
    Object? bodyPart = freezed,
    Object? movementType = freezed,
    Object? videoUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? skeletonData = freezed,
    Object? feedbackPrompt = freezed,
    Object? workoutSets = freezed,
    Object? routineId = freezed,
    Object? isHiddenFromHome = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ExerciseBaselineImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyPart: freezed == bodyPart
          ? _value.bodyPart
          : bodyPart // ignore: cast_nullable_to_non_nullable
              as BodyPart?,
      movementType: freezed == movementType
          ? _value.movementType
          : movementType // ignore: cast_nullable_to_non_nullable
              as MovementType?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      skeletonData: freezed == skeletonData
          ? _value._skeletonData
          : skeletonData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      feedbackPrompt: freezed == feedbackPrompt
          ? _value.feedbackPrompt
          : feedbackPrompt // ignore: cast_nullable_to_non_nullable
              as String?,
      workoutSets: freezed == workoutSets
          ? _value._workoutSets
          : workoutSets // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSet>?,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      isHiddenFromHome: null == isHiddenFromHome
          ? _value.isHiddenFromHome
          : isHiddenFromHome // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseBaselineImpl implements _ExerciseBaseline {
  const _$ExerciseBaselineImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'exercise_name') required this.exerciseName,
      @JsonKey(name: 'target_muscle') this.targetMuscle,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      this.bodyPart,
      @JsonKey(
          name: 'movement_type',
          fromJson: JsonConverters.movementTypeFromCode,
          toJson: JsonConverters.movementTypeToCode)
      this.movementType,
      @JsonKey(name: 'video_url') this.videoUrl,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      @JsonKey(name: 'skeleton_data') final Map<String, dynamic>? skeletonData,
      @JsonKey(name: 'feedback_prompt') this.feedbackPrompt,
      @JsonKey(name: 'workout_sets', includeToJson: false)
      final List<WorkoutSet>? workoutSets,
      @JsonKey(name: 'routine_id') this.routineId,
      @JsonKey(name: 'is_hidden_from_home') this.isHiddenFromHome = false,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _skeletonData = skeletonData,
        _workoutSets = workoutSets;

  factory _$ExerciseBaselineImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseBaselineImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
// 'BENCH_PRESS', 'SQUAT' 등
  @override
  @JsonKey(name: 'target_muscle')
  final String? targetMuscle;
// 'CHEST', 'LEGS'
  @override
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  final BodyPart? bodyPart;
// Enum: upper, lower, full
  @override
  @JsonKey(
      name: 'movement_type',
      fromJson: JsonConverters.movementTypeFromCode,
      toJson: JsonConverters.movementTypeToCode)
  final MovementType? movementType;
// Enum: push, pull
  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl;
// 원본/압축 영상 경로
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
// 리스트 표시용 썸네일
  final Map<String, dynamic>? _skeletonData;
// 리스트 표시용 썸네일
  @override
  @JsonKey(name: 'skeleton_data')
  Map<String, dynamic>? get skeletonData {
    final value = _skeletonData;
    if (value == null) return null;
    if (_skeletonData is EqualUnmodifiableMapView) return _skeletonData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

// JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  @override
  @JsonKey(name: 'feedback_prompt')
  final String? feedbackPrompt;
// "어깨 관절 개입 과다" 등 분석 내용
  final List<WorkoutSet>? _workoutSets;
// "어깨 관절 개입 과다" 등 분석 내용
  @override
  @JsonKey(name: 'workout_sets', includeToJson: false)
  List<WorkoutSet>? get workoutSets {
    final value = _workoutSets;
    if (value == null) return null;
    if (_workoutSets is EqualUnmodifiableListView) return _workoutSets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// 조인 쿼리 결과 매핑용 (읽기 전용)
  @override
  @JsonKey(name: 'routine_id')
  final String? routineId;
// 루틴 실행 이력 추적용
  @override
  @JsonKey(name: 'is_hidden_from_home')
  final bool isHiddenFromHome;
// 홈 화면에서 숨김 여부
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ExerciseBaseline(id: $id, userId: $userId, exerciseName: $exerciseName, targetMuscle: $targetMuscle, bodyPart: $bodyPart, movementType: $movementType, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, skeletonData: $skeletonData, feedbackPrompt: $feedbackPrompt, workoutSets: $workoutSets, routineId: $routineId, isHiddenFromHome: $isHiddenFromHome, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseBaselineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.bodyPart, bodyPart) ||
                other.bodyPart == bodyPart) &&
            (identical(other.movementType, movementType) ||
                other.movementType == movementType) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality()
                .equals(other._skeletonData, _skeletonData) &&
            (identical(other.feedbackPrompt, feedbackPrompt) ||
                other.feedbackPrompt == feedbackPrompt) &&
            const DeepCollectionEquality()
                .equals(other._workoutSets, _workoutSets) &&
            (identical(other.routineId, routineId) ||
                other.routineId == routineId) &&
            (identical(other.isHiddenFromHome, isHiddenFromHome) ||
                other.isHiddenFromHome == isHiddenFromHome) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      exerciseName,
      targetMuscle,
      bodyPart,
      movementType,
      videoUrl,
      thumbnailUrl,
      const DeepCollectionEquality().hash(_skeletonData),
      feedbackPrompt,
      const DeepCollectionEquality().hash(_workoutSets),
      routineId,
      isHiddenFromHome,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseBaselineImplCopyWith<_$ExerciseBaselineImpl> get copyWith =>
      __$$ExerciseBaselineImplCopyWithImpl<_$ExerciseBaselineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseBaselineImplToJson(
      this,
    );
  }
}

abstract class _ExerciseBaseline implements ExerciseBaseline {
  const factory _ExerciseBaseline(
      {@JsonKey(name: 'id') required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'exercise_name') required final String exerciseName,
      @JsonKey(name: 'target_muscle') final String? targetMuscle,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      final BodyPart? bodyPart,
      @JsonKey(
          name: 'movement_type',
          fromJson: JsonConverters.movementTypeFromCode,
          toJson: JsonConverters.movementTypeToCode)
      final MovementType? movementType,
      @JsonKey(name: 'video_url') final String? videoUrl,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      @JsonKey(name: 'skeleton_data') final Map<String, dynamic>? skeletonData,
      @JsonKey(name: 'feedback_prompt') final String? feedbackPrompt,
      @JsonKey(name: 'workout_sets', includeToJson: false)
      final List<WorkoutSet>? workoutSets,
      @JsonKey(name: 'routine_id') final String? routineId,
      @JsonKey(name: 'is_hidden_from_home') final bool isHiddenFromHome,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at')
      final DateTime? updatedAt}) = _$ExerciseBaselineImpl;

  factory _ExerciseBaseline.fromJson(Map<String, dynamic> json) =
      _$ExerciseBaselineImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'exercise_name')
  String get exerciseName;
  @override // 'BENCH_PRESS', 'SQUAT' 등
  @JsonKey(name: 'target_muscle')
  String? get targetMuscle;
  @override // 'CHEST', 'LEGS'
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  BodyPart? get bodyPart;
  @override // Enum: upper, lower, full
  @JsonKey(
      name: 'movement_type',
      fromJson: JsonConverters.movementTypeFromCode,
      toJson: JsonConverters.movementTypeToCode)
  MovementType? get movementType;
  @override // Enum: push, pull
  @JsonKey(name: 'video_url')
  String? get videoUrl;
  @override // 원본/압축 영상 경로
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override // 리스트 표시용 썸네일
  @JsonKey(name: 'skeleton_data')
  Map<String, dynamic>? get skeletonData;
  @override // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  @JsonKey(name: 'feedback_prompt')
  String? get feedbackPrompt;
  @override // "어깨 관절 개입 과다" 등 분석 내용
  @JsonKey(name: 'workout_sets', includeToJson: false)
  List<WorkoutSet>? get workoutSets;
  @override // 조인 쿼리 결과 매핑용 (읽기 전용)
  @JsonKey(name: 'routine_id')
  String? get routineId;
  @override // 루틴 실행 이력 추적용
  @JsonKey(name: 'is_hidden_from_home')
  bool get isHiddenFromHome;
  @override // 홈 화면에서 숨김 여부
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseBaselineImplCopyWith<_$ExerciseBaselineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
