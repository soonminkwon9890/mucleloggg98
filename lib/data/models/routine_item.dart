import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/exercise_enums.dart';
import '../../core/utils/json_converters.dart';

part 'routine_item.freezed.dart';
part 'routine_item.g.dart';

/// 루틴 아이템 모델
/// 루틴 아이템은 특정 기록(baseline_id)에 의존하지 않도록 이름과 타입 정보를 직접 저장합니다.
@freezed
class RoutineItem with _$RoutineItem {
  const factory RoutineItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'routine_id') required String routineId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @JsonKey(
      name: 'body_part',
      fromJson: JsonConverters.bodyPartFromCode,
      toJson: JsonConverters.bodyPartToCode,
    )
    BodyPart? bodyPart, // Enum: upper, lower, full (ExerciseBaseline과 동일)
    @JsonKey(
      name: 'movement_type',
      fromJson: JsonConverters.movementTypeFromCode,
      toJson: JsonConverters.movementTypeToCode,
    )
    MovementType? movementType, // Enum: push, pull (ExerciseBaseline과 동일)
    @JsonKey(
      name: 'sort_order',
      fromJson: JsonConverters.toInt,
    )
    @Default(0)
    int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _RoutineItem;

  factory RoutineItem.fromJson(Map<String, dynamic> json) =>
      _$RoutineItemFromJson(json);
}
