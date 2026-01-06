import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// 사용자 프로필 모델
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    String? experienceLevel, // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
    DateTime? createdAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

