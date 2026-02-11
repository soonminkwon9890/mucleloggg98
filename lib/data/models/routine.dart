import 'package:freezed_annotation/freezed_annotation.dart';
import 'routine_item.dart';

part 'routine.freezed.dart';
part 'routine.g.dart';

/// 루틴 모델
@freezed
class Routine with _$Routine {
  const factory Routine({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'routine_items', includeToJson: false) List<RoutineItem>? routineItems, // 조인 쿼리 결과 매핑용 (읽기 전용)
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Routine;

  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);
}

