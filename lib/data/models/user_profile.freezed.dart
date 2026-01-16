// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'experience_level')
  String? get experienceLevel =>
      throw _privateConstructorUsedError; // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
  @JsonKey(name: 'birth_date')
  DateTime? get birthDate => throw _privateConstructorUsedError; // 생년월일
  @JsonKey(name: 'gender')
  String? get gender =>
      throw _privateConstructorUsedError; // 성별 ('MALE', 'FEMALE')
  @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
  double? get height => throw _privateConstructorUsedError; // 키 (cm 단위)
  @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
  double? get weight => throw _privateConstructorUsedError; // 몸무게 (kg 단위)
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'experience_level') String? experienceLevel,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      @JsonKey(name: 'gender') String? gender,
      @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
      double? height,
      @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
      double? weight,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? experienceLevel = freezed,
    Object? birthDate = freezed,
    Object? gender = freezed,
    Object? height = freezed,
    Object? weight = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      experienceLevel: freezed == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double?,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'experience_level') String? experienceLevel,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      @JsonKey(name: 'gender') String? gender,
      @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
      double? height,
      @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
      double? weight,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? experienceLevel = freezed,
    Object? birthDate = freezed,
    Object? gender = freezed,
    Object? height = freezed,
    Object? weight = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      experienceLevel: freezed == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double?,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
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
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'experience_level') this.experienceLevel,
      @JsonKey(name: 'birth_date') this.birthDate,
      @JsonKey(name: 'gender') this.gender,
      @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
      this.height,
      @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
      this.weight,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'experience_level')
  final String? experienceLevel;
// 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
  @override
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
// 생년월일
  @override
  @JsonKey(name: 'gender')
  final String? gender;
// 성별 ('MALE', 'FEMALE')
  @override
  @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
  final double? height;
// 키 (cm 단위)
  @override
  @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
  final double? weight;
// 몸무게 (kg 단위)
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'UserProfile(id: $id, experienceLevel: $experienceLevel, birthDate: $birthDate, gender: $gender, height: $height, weight: $weight, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.experienceLevel, experienceLevel) ||
                other.experienceLevel == experienceLevel) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, experienceLevel, birthDate,
      gender, height, weight, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'experience_level') final String? experienceLevel,
          @JsonKey(name: 'birth_date') final DateTime? birthDate,
          @JsonKey(name: 'gender') final String? gender,
          @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
          final double? height,
          @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
          final double? weight,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'experience_level')
  String? get experienceLevel;
  @override // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
  @JsonKey(name: 'birth_date')
  DateTime? get birthDate;
  @override // 생년월일
  @JsonKey(name: 'gender')
  String? get gender;
  @override // 성별 ('MALE', 'FEMALE')
  @JsonKey(name: 'height', fromJson: JsonConverters.toDoubleNullable)
  double? get height;
  @override // 키 (cm 단위)
  @JsonKey(name: 'weight', fromJson: JsonConverters.toDoubleNullable)
  double? get weight;
  @override // 몸무게 (kg 단위)
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
