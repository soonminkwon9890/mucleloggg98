// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeState {
  List<ExerciseBaseline> get baselines => throw _privateConstructorUsedError;
  Map<String, List<ExerciseBaseline>> get groupedWorkouts =>
      throw _privateConstructorUsedError;
  double get totalVolume => throw _privateConstructorUsedError;
  String get mainFocusArea => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeStateCopyWith<HomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeStateCopyWith<$Res> {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) then) =
      _$HomeStateCopyWithImpl<$Res, HomeState>;
  @useResult
  $Res call(
      {List<ExerciseBaseline> baselines,
      Map<String, List<ExerciseBaseline>> groupedWorkouts,
      double totalVolume,
      String mainFocusArea,
      bool isLoading,
      String? errorMessage});
}

/// @nodoc
class _$HomeStateCopyWithImpl<$Res, $Val extends HomeState>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baselines = null,
    Object? groupedWorkouts = null,
    Object? totalVolume = null,
    Object? mainFocusArea = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      baselines: null == baselines
          ? _value.baselines
          : baselines // ignore: cast_nullable_to_non_nullable
              as List<ExerciseBaseline>,
      groupedWorkouts: null == groupedWorkouts
          ? _value.groupedWorkouts
          : groupedWorkouts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<ExerciseBaseline>>,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      mainFocusArea: null == mainFocusArea
          ? _value.mainFocusArea
          : mainFocusArea // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeStateImplCopyWith<$Res>
    implements $HomeStateCopyWith<$Res> {
  factory _$$HomeStateImplCopyWith(
          _$HomeStateImpl value, $Res Function(_$HomeStateImpl) then) =
      __$$HomeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ExerciseBaseline> baselines,
      Map<String, List<ExerciseBaseline>> groupedWorkouts,
      double totalVolume,
      String mainFocusArea,
      bool isLoading,
      String? errorMessage});
}

/// @nodoc
class __$$HomeStateImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$HomeStateImpl>
    implements _$$HomeStateImplCopyWith<$Res> {
  __$$HomeStateImplCopyWithImpl(
      _$HomeStateImpl _value, $Res Function(_$HomeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baselines = null,
    Object? groupedWorkouts = null,
    Object? totalVolume = null,
    Object? mainFocusArea = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$HomeStateImpl(
      baselines: null == baselines
          ? _value._baselines
          : baselines // ignore: cast_nullable_to_non_nullable
              as List<ExerciseBaseline>,
      groupedWorkouts: null == groupedWorkouts
          ? _value._groupedWorkouts
          : groupedWorkouts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<ExerciseBaseline>>,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      mainFocusArea: null == mainFocusArea
          ? _value.mainFocusArea
          : mainFocusArea // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$HomeStateImpl implements _HomeState {
  const _$HomeStateImpl(
      {final List<ExerciseBaseline> baselines = const [],
      final Map<String, List<ExerciseBaseline>> groupedWorkouts = const {},
      this.totalVolume = 0.0,
      this.mainFocusArea = '기록 없음',
      this.isLoading = false,
      this.errorMessage})
      : _baselines = baselines,
        _groupedWorkouts = groupedWorkouts;

  final List<ExerciseBaseline> _baselines;
  @override
  @JsonKey()
  List<ExerciseBaseline> get baselines {
    if (_baselines is EqualUnmodifiableListView) return _baselines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_baselines);
  }

  final Map<String, List<ExerciseBaseline>> _groupedWorkouts;
  @override
  @JsonKey()
  Map<String, List<ExerciseBaseline>> get groupedWorkouts {
    if (_groupedWorkouts is EqualUnmodifiableMapView) return _groupedWorkouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_groupedWorkouts);
  }

  @override
  @JsonKey()
  final double totalVolume;
  @override
  @JsonKey()
  final String mainFocusArea;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'HomeState(baselines: $baselines, groupedWorkouts: $groupedWorkouts, totalVolume: $totalVolume, mainFocusArea: $mainFocusArea, isLoading: $isLoading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._baselines, _baselines) &&
            const DeepCollectionEquality()
                .equals(other._groupedWorkouts, _groupedWorkouts) &&
            (identical(other.totalVolume, totalVolume) ||
                other.totalVolume == totalVolume) &&
            (identical(other.mainFocusArea, mainFocusArea) ||
                other.mainFocusArea == mainFocusArea) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_baselines),
      const DeepCollectionEquality().hash(_groupedWorkouts),
      totalVolume,
      mainFocusArea,
      isLoading,
      errorMessage);

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeStateImplCopyWith<_$HomeStateImpl> get copyWith =>
      __$$HomeStateImplCopyWithImpl<_$HomeStateImpl>(this, _$identity);
}

abstract class _HomeState implements HomeState {
  const factory _HomeState(
      {final List<ExerciseBaseline> baselines,
      final Map<String, List<ExerciseBaseline>> groupedWorkouts,
      final double totalVolume,
      final String mainFocusArea,
      final bool isLoading,
      final String? errorMessage}) = _$HomeStateImpl;

  @override
  List<ExerciseBaseline> get baselines;
  @override
  Map<String, List<ExerciseBaseline>> get groupedWorkouts;
  @override
  double get totalVolume;
  @override
  String get mainFocusArea;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeStateImplCopyWith<_$HomeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
