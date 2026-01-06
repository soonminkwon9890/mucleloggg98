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
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get exerciseName =>
      throw _privateConstructorUsedError; // 'BENCH_PRESS', 'SQUAT' 등
  String? get targetMuscle =>
      throw _privateConstructorUsedError; // 'CHEST', 'LEGS'
  String? get bodyPart =>
      throw _privateConstructorUsedError; // 'UPPER', 'LOWER', 'FULL'
  String? get movementType =>
      throw _privateConstructorUsedError; // 'PUSH', 'PULL'
  String? get videoUrl => throw _privateConstructorUsedError; // 원본/압축 영상 경로
  String? get thumbnailUrl => throw _privateConstructorUsedError; // 리스트 표시용 썸네일
  Map<String, dynamic>? get skeletonData =>
      throw _privateConstructorUsedError; // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  String? get feedbackPrompt =>
      throw _privateConstructorUsedError; // "어깨 관절 개입 과다" 등 분석 내용
  DateTime? get createdAt => throw _privateConstructorUsedError;

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
      {String id,
      String userId,
      String exerciseName,
      String? targetMuscle,
      String? bodyPart,
      String? movementType,
      String? videoUrl,
      String? thumbnailUrl,
      Map<String, dynamic>? skeletonData,
      String? feedbackPrompt,
      DateTime? createdAt});
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
              as String?,
      movementType: freezed == movementType
          ? _value.movementType
          : movementType // ignore: cast_nullable_to_non_nullable
              as String?,
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
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
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
      {String id,
      String userId,
      String exerciseName,
      String? targetMuscle,
      String? bodyPart,
      String? movementType,
      String? videoUrl,
      String? thumbnailUrl,
      Map<String, dynamic>? skeletonData,
      String? feedbackPrompt,
      DateTime? createdAt});
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
    Object? createdAt = freezed,
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
              as String?,
      movementType: freezed == movementType
          ? _value.movementType
          : movementType // ignore: cast_nullable_to_non_nullable
              as String?,
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
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseBaselineImpl implements _ExerciseBaseline {
  const _$ExerciseBaselineImpl(
      {required this.id,
      required this.userId,
      required this.exerciseName,
      this.targetMuscle,
      this.bodyPart,
      this.movementType,
      this.videoUrl,
      this.thumbnailUrl,
      final Map<String, dynamic>? skeletonData,
      this.feedbackPrompt,
      this.createdAt})
      : _skeletonData = skeletonData;

  factory _$ExerciseBaselineImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseBaselineImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String exerciseName;
// 'BENCH_PRESS', 'SQUAT' 등
  @override
  final String? targetMuscle;
// 'CHEST', 'LEGS'
  @override
  final String? bodyPart;
// 'UPPER', 'LOWER', 'FULL'
  @override
  final String? movementType;
// 'PUSH', 'PULL'
  @override
  final String? videoUrl;
// 원본/압축 영상 경로
  @override
  final String? thumbnailUrl;
// 리스트 표시용 썸네일
  final Map<String, dynamic>? _skeletonData;
// 리스트 표시용 썸네일
  @override
  Map<String, dynamic>? get skeletonData {
    final value = _skeletonData;
    if (value == null) return null;
    if (_skeletonData is EqualUnmodifiableMapView) return _skeletonData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

// JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  @override
  final String? feedbackPrompt;
// "어깨 관절 개입 과다" 등 분석 내용
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ExerciseBaseline(id: $id, userId: $userId, exerciseName: $exerciseName, targetMuscle: $targetMuscle, bodyPart: $bodyPart, movementType: $movementType, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, skeletonData: $skeletonData, feedbackPrompt: $feedbackPrompt, createdAt: $createdAt)';
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
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
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
      createdAt);

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
      {required final String id,
      required final String userId,
      required final String exerciseName,
      final String? targetMuscle,
      final String? bodyPart,
      final String? movementType,
      final String? videoUrl,
      final String? thumbnailUrl,
      final Map<String, dynamic>? skeletonData,
      final String? feedbackPrompt,
      final DateTime? createdAt}) = _$ExerciseBaselineImpl;

  factory _ExerciseBaseline.fromJson(Map<String, dynamic> json) =
      _$ExerciseBaselineImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get exerciseName;
  @override // 'BENCH_PRESS', 'SQUAT' 등
  String? get targetMuscle;
  @override // 'CHEST', 'LEGS'
  String? get bodyPart;
  @override // 'UPPER', 'LOWER', 'FULL'
  String? get movementType;
  @override // 'PUSH', 'PULL'
  String? get videoUrl;
  @override // 원본/압축 영상 경로
  String? get thumbnailUrl;
  @override // 리스트 표시용 썸네일
  Map<String, dynamic>? get skeletonData;
  @override // JSONB: 기준 자세의 관절 좌표 데이터 캐싱
  String? get feedbackPrompt;
  @override // "어깨 관절 개입 과다" 등 분석 내용
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseBaselineImplCopyWith<_$ExerciseBaselineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
