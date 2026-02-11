import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/json_converters.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// 사용자 프로필 모델
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'experience_level') String? experienceLevel, // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
    @JsonKey(name: 'birth_date') DateTime? birthDate, // 생년월일
    @JsonKey(name: 'gender') String? gender, // 성별 ('MALE', 'FEMALE')
    @JsonKey(name: 'is_premium') bool? isPremium,
    @JsonKey(name: 'premium_until') DateTime? premiumUntil,
    @JsonKey(name: 'is_admin') bool? isAdmin,
    @JsonKey(name: 'is_coupon_available') bool? isCouponAvailable,
    @JsonKey(
      name: 'height',
      fromJson: JsonConverters.toDoubleNullable,
    )
    double? height, // 키 (cm 단위)
    @JsonKey(
      name: 'weight',
      fromJson: JsonConverters.toDoubleNullable,
    )
    double? weight, // 몸무게 (kg 단위)
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

