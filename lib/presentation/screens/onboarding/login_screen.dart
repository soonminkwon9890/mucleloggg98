import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';

/// 로그인 화면
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // 웹 OAuth 리다이렉트 후 signedIn 이벤트를 감지해 로딩을 해제합니다.
    // 실제 화면 전환은 main.dart의 StreamBuilder(onAuthStateChange)가 담당합니다.
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.signedIn) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      // 1. sign_in_with_apple 패키지로 Apple ID 자격증명 획득
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) throw Exception('Apple identity token이 null입니다.');

      // 2. Supabase에 Apple ID 토큰으로 로그인
      final AuthResponse res =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      if (res.session != null) {
        debugPrint('Apple 로그인 성공');
        // 화면 전환은 main.dart의 StreamBuilder(onAuthStateChange)가 처리합니다.
      }
    } catch (e) {
      debugPrint('Apple 로그인 오류: $e');
      if (mounted) {
        final errorMessage = e.toString().contains('canceled') ||
                e.toString().contains('취소') ||
                e.toString().contains('AuthorizationErrorCode.canceled')
            ? '로그인이 취소되었습니다.'
            : 'Apple 로그인에 실패했습니다. 다시 시도해주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
      // 화면 전환은 main.dart의 StreamBuilder(onAuthStateChange)가 처리합니다.
    } catch (e) {
      debugPrint('구글 로그인 오류: $e');
      if (mounted) {
        final errorMessage = e.toString().contains('취소')
            ? '로그인이 취소되었습니다.'
            : '구글 로그인에 실패했습니다. 다시 시도해주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
                'MuscleLog',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI 강도 분석 및 점진적 과부하 코칭',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[700]
                          : Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const ButtonLoadingIndicator()
                      : const Text('Google로 계속하기'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                child: SignInWithAppleButton(
                  onPressed: _isLoading ? () {} : _signInWithApple,
                  style: Theme.of(context).brightness == Brightness.light
                      ? SignInWithAppleButtonStyle.black
                      : SignInWithAppleButtonStyle.white,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

