import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// 인증 및 프로필 레포지토리
class AuthRepository {
  final _client = SupabaseService.client;

  // Google Sign-In Client IDs
  // Web Client ID: Supabase에 등록된 OAuth Client ID (ID Token 검증용 - serverClientId)
  // iOS Client ID: Google Cloud Console에서 생성한 iOS 앱용 Client ID (clientId)
  static const String _webClientId =
      '503997494754-dm502sekm7kvrsmo2es1jsbc3mfmhm7d.apps.googleusercontent.com';
  static const String _iosClientId =
      '503997494754-k1q97404sbquc6fheabjp49k6c2nu2s9.apps.googleusercontent.com';

  /// 로그아웃
  Future<void> signOut() async {
    // Google Sign-In 로그아웃도 함께 처리
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {
        // Google Sign-In 로그아웃 실패는 무시
      }
    }
    await _client.auth.signOut();
  }

  /// 계정 삭제 (데이터 삭제 + Auth 계정 RPC 삭제)
  ///
  /// 순서(권장): 자식(workout_sets/planned_workouts) -> 부모(exercise_baselines/profiles) -> auth.users(RPC)
  Future<void> deleteAccount(String userId) async {
    // 1) workout_sets 삭제: workout_sets에 user_id가 없으므로 baseline_id 목록을 먼저 구함
    final baselineRows = await _client
        .from('exercise_baselines')
        .select('id')
        .eq('user_id', userId);

    final baselineIds = (baselineRows as List)
        .map((e) => e['id'] as String?)
        .whereType<String>()
        .toList();

    // ids가 비어있지 않을 때만 IN 삭제 실행 (IN [] 방지)
    if (baselineIds.isNotEmpty) {
      await _client
          .from('workout_sets')
          .delete()
          .inFilter('baseline_id', baselineIds);
    }

    // 2) planned_workouts 삭제
    await _client.from('planned_workouts').delete().eq('user_id', userId);

    // 3) exercise_baselines 삭제
    await _client.from('exercise_baselines').delete().eq('user_id', userId);

    // 4) (선택) profiles 삭제
    await _client.from('profiles').delete().eq('id', userId);

    // 5) Auth 유저 삭제 (RPC)
    await Supabase.instance.client.rpc('delete_user_account');
  }

  /// 구글 로그인 (네이티브 + 웹 통합)
  Future<AuthResponse> signInWithGoogle() async {
    // 웹 환경에서는 기존 OAuth 방식 사용
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.musclelog://login-callback',
      );
      // OAuth는 리다이렉트 방식이므로 여기서 AuthResponse를 반환하지 않음
      throw Exception('웹 OAuth는 리다이렉트 방식입니다.');
    }

    // iOS/Android: 네이티브 Google Sign-In 사용
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _iosClientId : null,
        serverClientId: _webClientId, // Supabase 연동용 (ID Token 검증)
      );

      // 기존 로그인 세션 정리
      await googleSignIn.signOut();

      // 네이티브 구글 로그인 팝업 표시
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('구글 로그인이 취소되었습니다.');
      }

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('구글 ID Token을 가져올 수 없습니다.');
      }

      // Supabase에 ID Token으로 로그인
      final AuthResponse response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } on AuthException catch (e) {
      throw Exception('Supabase 인증 오류: ${e.message}');
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
