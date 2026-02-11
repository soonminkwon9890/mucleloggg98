// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      experienceLevel: json['experience_level'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      gender: json['gender'] as String?,
      isPremium: json['is_premium'] as bool?,
      premiumUntil: json['premium_until'] == null
          ? null
          : DateTime.parse(json['premium_until'] as String),
      isAdmin: json['is_admin'] as bool?,
      isCouponAvailable: json['is_coupon_available'] as bool?,
      height: JsonConverters.toDoubleNullable(json['height']),
      weight: JsonConverters.toDoubleNullable(json['weight']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'experience_level': instance.experienceLevel,
      'birth_date': instance.birthDate?.toIso8601String(),
      'gender': instance.gender,
      'is_premium': instance.isPremium,
      'premium_until': instance.premiumUntil?.toIso8601String(),
      'is_admin': instance.isAdmin,
      'is_coupon_available': instance.isCouponAvailable,
      'height': instance.height,
      'weight': instance.weight,
      'created_at': instance.createdAt?.toIso8601String(),
    };
