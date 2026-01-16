import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// 인증 및 프로필 레포지토리
class AuthRepository {
  final _client = SupabaseService.client;

  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 회원가입
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.musclelog://login-callback',
      );
    } catch (e) {
      throw Exception('구글 로그인 실패: $e');
    }
  }

  /// 현재 사용자 프로필 가져오기
  Future<UserProfile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final response =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    if (response == null) return null;

    return UserProfile.fromJson(response);
  }

  /// 프로필 저장/업데이트
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final data = profile.toJson();
    data['id'] = user.id;
    
    // DateTime 필드를 ISO 8601 문자열로 변환
    if (data['birth_date'] != null && data['birth_date'] is DateTime) {
      data['birth_date'] = (data['birth_date'] as DateTime).toIso8601String();
    }
    if (data['created_at'] != null && data['created_at'] is DateTime) {
      data['created_at'] = (data['created_at'] as DateTime).toIso8601String();
    }

    await _client.from('profiles').upsert(data);

    return profile.copyWith(id: user.id);
  }

  /// 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return SupabaseService.currentUser?.id;
  }

  /// 인증 상태 스트림
  Stream<bool> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      return event.session != null;
    });
  }
}
