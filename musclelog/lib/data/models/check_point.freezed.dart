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
  @JsonKey(name: 'check_video_path')
  String get checkVideoPath =>
      throw _privateConstructorUsedError; // 중간 점검 영상 경로
  @JsonKey(name: 'comparison_result')
  Map<String, dynamic>? get comparisonResult =>
      throw _privateConstructorUsedError; // JSONB: { "rom_change": -10, "muscle_activation_change": +15... }
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
      @JsonKey(name: 'check_video_path') String checkVideoPath,
      @JsonKey(name: 'comparison_result')
      Map<String, dynamic>? comparisonResult,
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
    Object? checkVideoPath = null,
    Object? comparisonResult = freezed,
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
      checkVideoPath: null == checkVideoPath
          ? _value.checkVideoPath
          : checkVideoPath // ignore: cast_nullable_to_non_nullable
              as String,
      comparisonResult: freezed == comparisonResult
          ? _value.comparisonResult
          : comparisonResult // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
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
      @JsonKey(name: 'check_video_path') String checkVideoPath,
      @JsonKey(name: 'comparison_result')
      Map<String, dynamic>? comparisonResult,
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
    Object? checkVideoPath = null,
    Object? comparisonResult = freezed,
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
      checkVideoPath: null == checkVideoPath
          ? _value.checkVideoPath
          : checkVideoPath // ignore: cast_nullable_to_non_nullable
              as String,
      comparisonResult: freezed == comparisonResult
          ? _value._comparisonResult
          : comparisonResult // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
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
      @JsonKey(name: 'check_video_path') required this.checkVideoPath,
      @JsonKey(name: 'comparison_result')
      final Map<String, dynamic>? comparisonResult,
      @JsonKey(name: 'created_at') this.createdAt})
      : _comparisonResult = comparisonResult;

  factory _$CheckPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckPointImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'baseline_id')
  final String baselineId;
  @override
  @JsonKey(name: 'check_video_path')
  final String checkVideoPath;
// 중간 점검 영상 경로
  final Map<String, dynamic>? _comparisonResult;
// 중간 점검 영상 경로
  @override
  @JsonKey(name: 'comparison_result')
  Map<String, dynamic>? get comparisonResult {
    final value = _comparisonResult;
    if (value == null) return null;
    if (_comparisonResult is EqualUnmodifiableMapView) return _comparisonResult;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

// JSONB: { "rom_change": -10, "muscle_activation_change": +15... }
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CheckPoint(id: $id, baselineId: $baselineId, checkVideoPath: $checkVideoPath, comparisonResult: $comparisonResult, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckPointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.baselineId, baselineId) ||
                other.baselineId == baselineId) &&
            (identical(other.checkVideoPath, checkVideoPath) ||
                other.checkVideoPath == checkVideoPath) &&
            const DeepCollectionEquality()
                .equals(other._comparisonResult, _comparisonResult) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, baselineId, checkVideoPath,
      const DeepCollectionEquality().hash(_comparisonResult), createdAt);

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
      @JsonKey(name: 'check_video_path') required final String checkVideoPath,
      @JsonKey(name: 'comparison_result')
      final Map<String, dynamic>? comparisonResult,
      @JsonKey(name: 'created_at')
      final DateTime? createdAt}) = _$CheckPointImpl;

  factory _CheckPoint.fromJson(Map<String, dynamic> json) =
      _$CheckPointImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'baseline_id')
  String get baselineId;
  @override
  @JsonKey(name: 'check_video_path')
  String get checkVideoPath;
  @override // 중간 점검 영상 경로
  @JsonKey(name: 'comparison_result')
  Map<String, dynamic>? get comparisonResult;
  @override // JSONB: { "rom_change": -10, "muscle_activation_change": +15... }
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CheckPointImplCopyWith<_$CheckPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
