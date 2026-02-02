// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoutineItem _$RoutineItemFromJson(Map<String, dynamic> json) {
  return _RoutineItem.fromJson(json);
}

/// @nodoc
mixin _$RoutineItem {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'routine_id')
  String get routineId => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise_name')
  String get exerciseName => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  BodyPart? get bodyPart =>
      throw _privateConstructorUsedError; // Enum: upper, lower, full (ExerciseBaseline과 동일)
  @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RoutineItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoutineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoutineItemCopyWith<RoutineItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineItemCopyWith<$Res> {
  factory $RoutineItemCopyWith(
          RoutineItem value, $Res Function(RoutineItem) then) =
      _$RoutineItemCopyWithImpl<$Res, RoutineItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'routine_id') String routineId,
      @JsonKey(name: 'exercise_name') String exerciseName,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      BodyPart? bodyPart,
      @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
      int sortOrder,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$RoutineItemCopyWithImpl<$Res, $Val extends RoutineItem>
    implements $RoutineItemCopyWith<$Res> {
  _$RoutineItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoutineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = null,
    Object? exerciseName = null,
    Object? bodyPart = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: null == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      bodyPart: freezed == bodyPart
          ? _value.bodyPart
          : bodyPart // ignore: cast_nullable_to_non_nullable
              as BodyPart?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineItemImplCopyWith<$Res>
    implements $RoutineItemCopyWith<$Res> {
  factory _$$RoutineItemImplCopyWith(
          _$RoutineItemImpl value, $Res Function(_$RoutineItemImpl) then) =
      __$$RoutineItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'routine_id') String routineId,
      @JsonKey(name: 'exercise_name') String exerciseName,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      BodyPart? bodyPart,
      @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
      int sortOrder,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$RoutineItemImplCopyWithImpl<$Res>
    extends _$RoutineItemCopyWithImpl<$Res, _$RoutineItemImpl>
    implements _$$RoutineItemImplCopyWith<$Res> {
  __$$RoutineItemImplCopyWithImpl(
      _$RoutineItemImpl _value, $Res Function(_$RoutineItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoutineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = null,
    Object? exerciseName = null,
    Object? bodyPart = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$RoutineItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: null == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      bodyPart: freezed == bodyPart
          ? _value.bodyPart
          : bodyPart // ignore: cast_nullable_to_non_nullable
              as BodyPart?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineItemImpl implements _RoutineItem {
  const _$RoutineItemImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'routine_id') required this.routineId,
      @JsonKey(name: 'exercise_name') required this.exerciseName,
      @JsonKey(
          name: 'body_part',
          fromJson: JsonConverters.bodyPartFromCode,
          toJson: JsonConverters.bodyPartToCode)
      this.bodyPart,
      @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
      this.sortOrder = 0,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$RoutineItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineItemImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'routine_id')
  final String routineId;
  @override
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @override
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  final BodyPart? bodyPart;
// Enum: upper, lower, full (ExerciseBaseline과 동일)
  @override
  @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
  final int sortOrder;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RoutineItem(id: $id, routineId: $routineId, exerciseName: $exerciseName, bodyPart: $bodyPart, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routineId, routineId) ||
                other.routineId == routineId) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.bodyPart, bodyPart) ||
                other.bodyPart == bodyPart) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, routineId, exerciseName, bodyPart, sortOrder, createdAt);

  /// Create a copy of RoutineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineItemImplCopyWith<_$RoutineItemImpl> get copyWith =>
      __$$RoutineItemImplCopyWithImpl<_$RoutineItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineItemImplToJson(
      this,
    );
  }
}

abstract class _RoutineItem implements RoutineItem {
  const factory _RoutineItem(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'routine_id') required final String routineId,
          @JsonKey(name: 'exercise_name') required final String exerciseName,
          @JsonKey(
              name: 'body_part',
              fromJson: JsonConverters.bodyPartFromCode,
              toJson: JsonConverters.bodyPartToCode)
          final BodyPart? bodyPart,
          @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
          final int sortOrder,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$RoutineItemImpl;

  factory _RoutineItem.fromJson(Map<String, dynamic> json) =
      _$RoutineItemImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'routine_id')
  String get routineId;
  @override
  @JsonKey(name: 'exercise_name')
  String get exerciseName;
  @override
  @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode)
  BodyPart? get bodyPart; // Enum: upper, lower, full (ExerciseBaseline과 동일)
  @override
  @JsonKey(name: 'sort_order', fromJson: JsonConverters.toInt)
  int get sortOrder;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of RoutineItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoutineItemImplCopyWith<_$RoutineItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
