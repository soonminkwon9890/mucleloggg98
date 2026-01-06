// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutSet _$WorkoutSetFromJson(Map<String, dynamic> json) {
  return _WorkoutSet.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSet {
  String get id => throw _privateConstructorUsedError;
  String get baselineId => throw _privateConstructorUsedError; // 어떤 운동의 로그인지 연결
  double get weight => throw _privateConstructorUsedError; // 무게 (kg)
  int get reps => throw _privateConstructorUsedError; // 횟수
  int? get rpe => throw _privateConstructorUsedError; // 1~10
  String? get rpeLevel =>
      throw _privateConstructorUsedError; // 'LOW', 'MEDIUM', 'HIGH' (하위 호환)
  double? get estimated1rm => throw _privateConstructorUsedError; // 계산된 1RM
  bool get isAiSuggested => throw _privateConstructorUsedError; // AI 추천 값 수용 여부
  double? get performanceScore =>
      throw _privateConstructorUsedError; // 추가 성능 점수
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSetCopyWith<WorkoutSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSetCopyWith<$Res> {
  factory $WorkoutSetCopyWith(
          WorkoutSet value, $Res Function(WorkoutSet) then) =
      _$WorkoutSetCopyWithImpl<$Res, WorkoutSet>;
  @useResult
  $Res call(
      {String id,
      String baselineId,
      double weight,
      int reps,
      int? rpe,
      String? rpeLevel,
      double? estimated1rm,
      bool isAiSuggested,
      double? performanceScore,
      DateTime? createdAt});
}

/// @nodoc
class _$WorkoutSetCopyWithImpl<$Res, $Val extends WorkoutSet>
    implements $WorkoutSetCopyWith<$Res> {
  _$WorkoutSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? baselineId = null,
    Object? weight = null,
    Object? reps = null,
    Object? rpe = freezed,
    Object? rpeLevel = freezed,
    Object? estimated1rm = freezed,
    Object? isAiSuggested = null,
    Object? performanceScore = freezed,
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
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      rpeLevel: freezed == rpeLevel
          ? _value.rpeLevel
          : rpeLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      estimated1rm: freezed == estimated1rm
          ? _value.estimated1rm
          : estimated1rm // ignore: cast_nullable_to_non_nullable
              as double?,
      isAiSuggested: null == isAiSuggested
          ? _value.isAiSuggested
          : isAiSuggested // ignore: cast_nullable_to_non_nullable
              as bool,
      performanceScore: freezed == performanceScore
          ? _value.performanceScore
          : performanceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSetImplCopyWith<$Res>
    implements $WorkoutSetCopyWith<$Res> {
  factory _$$WorkoutSetImplCopyWith(
          _$WorkoutSetImpl value, $Res Function(_$WorkoutSetImpl) then) =
      __$$WorkoutSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String baselineId,
      double weight,
      int reps,
      int? rpe,
      String? rpeLevel,
      double? estimated1rm,
      bool isAiSuggested,
      double? performanceScore,
      DateTime? createdAt});
}

/// @nodoc
class __$$WorkoutSetImplCopyWithImpl<$Res>
    extends _$WorkoutSetCopyWithImpl<$Res, _$WorkoutSetImpl>
    implements _$$WorkoutSetImplCopyWith<$Res> {
  __$$WorkoutSetImplCopyWithImpl(
      _$WorkoutSetImpl _value, $Res Function(_$WorkoutSetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? baselineId = null,
    Object? weight = null,
    Object? reps = null,
    Object? rpe = freezed,
    Object? rpeLevel = freezed,
    Object? estimated1rm = freezed,
    Object? isAiSuggested = null,
    Object? performanceScore = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$WorkoutSetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      baselineId: null == baselineId
          ? _value.baselineId
          : baselineId // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      rpeLevel: freezed == rpeLevel
          ? _value.rpeLevel
          : rpeLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      estimated1rm: freezed == estimated1rm
          ? _value.estimated1rm
          : estimated1rm // ignore: cast_nullable_to_non_nullable
              as double?,
      isAiSuggested: null == isAiSuggested
          ? _value.isAiSuggested
          : isAiSuggested // ignore: cast_nullable_to_non_nullable
              as bool,
      performanceScore: freezed == performanceScore
          ? _value.performanceScore
          : performanceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSetImpl implements _WorkoutSet {
  const _$WorkoutSetImpl(
      {required this.id,
      required this.baselineId,
      required this.weight,
      required this.reps,
      this.rpe,
      this.rpeLevel,
      this.estimated1rm,
      this.isAiSuggested = false,
      this.performanceScore,
      this.createdAt});

  factory _$WorkoutSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSetImplFromJson(json);

  @override
  final String id;
  @override
  final String baselineId;
// 어떤 운동의 로그인지 연결
  @override
  final double weight;
// 무게 (kg)
  @override
  final int reps;
// 횟수
  @override
  final int? rpe;
// 1~10
  @override
  final String? rpeLevel;
// 'LOW', 'MEDIUM', 'HIGH' (하위 호환)
  @override
  final double? estimated1rm;
// 계산된 1RM
  @override
  @JsonKey()
  final bool isAiSuggested;
// AI 추천 값 수용 여부
  @override
  final double? performanceScore;
// 추가 성능 점수
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'WorkoutSet(id: $id, baselineId: $baselineId, weight: $weight, reps: $reps, rpe: $rpe, rpeLevel: $rpeLevel, estimated1rm: $estimated1rm, isAiSuggested: $isAiSuggested, performanceScore: $performanceScore, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.baselineId, baselineId) ||
                other.baselineId == baselineId) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.rpeLevel, rpeLevel) ||
                other.rpeLevel == rpeLevel) &&
            (identical(other.estimated1rm, estimated1rm) ||
                other.estimated1rm == estimated1rm) &&
            (identical(other.isAiSuggested, isAiSuggested) ||
                other.isAiSuggested == isAiSuggested) &&
            (identical(other.performanceScore, performanceScore) ||
                other.performanceScore == performanceScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, baselineId, weight, reps,
      rpe, rpeLevel, estimated1rm, isAiSuggested, performanceScore, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSetImplCopyWith<_$WorkoutSetImpl> get copyWith =>
      __$$WorkoutSetImplCopyWithImpl<_$WorkoutSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSetImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSet implements WorkoutSet {
  const factory _WorkoutSet(
      {required final String id,
      required final String baselineId,
      required final double weight,
      required final int reps,
      final int? rpe,
      final String? rpeLevel,
      final double? estimated1rm,
      final bool isAiSuggested,
      final double? performanceScore,
      final DateTime? createdAt}) = _$WorkoutSetImpl;

  factory _WorkoutSet.fromJson(Map<String, dynamic> json) =
      _$WorkoutSetImpl.fromJson;

  @override
  String get id;
  @override
  String get baselineId;
  @override // 어떤 운동의 로그인지 연결
  double get weight;
  @override // 무게 (kg)
  int get reps;
  @override // 횟수
  int? get rpe;
  @override // 1~10
  String? get rpeLevel;
  @override // 'LOW', 'MEDIUM', 'HIGH' (하위 호환)
  double? get estimated1rm;
  @override // 계산된 1RM
  bool get isAiSuggested;
  @override // AI 추천 값 수용 여부
  double? get performanceScore;
  @override // 추가 성능 점수
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSetImplCopyWith<_$WorkoutSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
