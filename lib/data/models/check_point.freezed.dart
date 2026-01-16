// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CheckPoint _$CheckPointFromJson(Map<String, dynamic> json) {
  return _CheckPoint.fromJson(json);
}

/// @nodoc
mixin _$CheckPoint {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'baseline_id')
  String get baselineId => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_url')
  String get videoUrl => throw _privateConstructorUsedError; // 중간 검사 영상 URL
  @JsonKey(name: 'analysis_result')
  String? get analysisResult =>
      throw _privateConstructorUsedError; // AI 분석 결과 (JSON 형태 or 텍스트)
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CheckPointCopyWith<CheckPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckPointCopyWith<$Res> {
  factory $CheckPointCopyWith(
          CheckPoint value, $Res Function(CheckPoint) then) =
      _$CheckPointCopyWithImpl<$Res, CheckPoint>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'baseline_id') String baselineId,
      @JsonKey(name: 'video_url') String videoUrl,
      @JsonKey(name: 'analysis_result') String? analysisResult,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$CheckPointCopyWithImpl<$Res, $Val extends CheckPoint>
    implements $CheckPointCopyWith<$Res> {
  _$CheckPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? baselineId = null,
    Object? videoUrl = null,
    Object? analysisResult = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      baselineId: null == baselineId
          ? _value.baselineId
          : baselineId // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: null == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      analysisResult: freezed == analysisResult
          ? _value.analysisResult
          : analysisResult // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckPointImplCopyWith<$Res>
    implements $CheckPointCopyWith<$Res> {
  factory _$$CheckPointImplCopyWith(
          _$CheckPointImpl value, $Res Function(_$CheckPointImpl) then) =
      __$$CheckPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'baseline_id') String baselineId,
      @JsonKey(name: 'video_url') String videoUrl,
      @JsonKey(name: 'analysis_result') String? analysisResult,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$CheckPointImplCopyWithImpl<$Res>
    extends _$CheckPointCopyWithImpl<$Res, _$CheckPointImpl>
    implements _$$CheckPointImplCopyWith<$Res> {
  __$$CheckPointImplCopyWithImpl(
      _$CheckPointImpl _value, $Res Function(_$CheckPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? baselineId = null,
    Object? videoUrl = null,
    Object? analysisResult = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$CheckPointImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      baselineId: null == baselineId
          ? _value.baselineId
          : baselineId // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: null == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      analysisResult: freezed == analysisResult
          ? _value.analysisResult
          : analysisResult // ignore: cast_nullable_to_non_nullable
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
class _$CheckPointImpl implements _CheckPoint {
  const _$CheckPointImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'baseline_id') required this.baselineId,
      @JsonKey(name: 'video_url') required this.videoUrl,
      @JsonKey(name: 'analysis_result') this.analysisResult,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$CheckPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckPointImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'baseline_id')
  final String baselineId;
  @override
  @JsonKey(name: 'video_url')
  final String videoUrl;
// 중간 검사 영상 URL
  @override
  @JsonKey(name: 'analysis_result')
  final String? analysisResult;
// AI 분석 결과 (JSON 형태 or 텍스트)
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CheckPoint(id: $id, baselineId: $baselineId, videoUrl: $videoUrl, analysisResult: $analysisResult, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckPointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.baselineId, baselineId) ||
                other.baselineId == baselineId) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.analysisResult, analysisResult) ||
                other.analysisResult == analysisResult) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, baselineId, videoUrl, analysisResult, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckPointImplCopyWith<_$CheckPointImpl> get copyWith =>
      __$$CheckPointImplCopyWithImpl<_$CheckPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckPointImplToJson(
      this,
    );
  }
}

abstract class _CheckPoint implements CheckPoint {
  const factory _CheckPoint(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'baseline_id') required final String baselineId,
          @JsonKey(name: 'video_url') required final String videoUrl,
          @JsonKey(name: 'analysis_result') final String? analysisResult,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$CheckPointImpl;

  factory _CheckPoint.fromJson(Map<String, dynamic> json) =
      _$CheckPointImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'baseline_id')
  String get baselineId;
  @override
  @JsonKey(name: 'video_url')
  String get videoUrl;
  @override // 중간 검사 영상 URL
  @JsonKey(name: 'analysis_result')
  String? get analysisResult;
  @override // AI 분석 결과 (JSON 형태 or 텍스트)
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CheckPointImplCopyWith<_$CheckPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
