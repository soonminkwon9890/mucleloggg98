import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../workout/main_screen.dart';

/// 로그인 화면
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // OAuth 리다이렉트 후 인증 상태 변경 감지
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && mounted) {
        _navigateAfterAuth();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleSignUpMode() {
    FocusScope.of(context).unfocus();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _isSignUp = !_isSignUp);
  }

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;

    // 프로필 확인 없이 바로 MainScreen으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);

      if (_isSignUp) {
        await repository.signUp(_emailController.text, _passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await repository.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          await _navigateAfterAuth();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${e.toString()}')),
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
      // OAuth는 리다이렉트를 사용하므로 여기서는 완료되지 않음
      // 인증 상태 변경은 initState에서 등록한 리스너를 통해 감지됨
    } catch (e) {
      debugPrint('구글 로그인 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구글 설정 오류입니다. 관리자에게 문의하세요.'),
          ),
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
      appBar: AppBar(
        title: const Text('MuscleLog'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MuscleLog',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI 강도 분석 및 점진적 과부하 코칭',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? '회원가입' : '로그인'),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('또는', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('구글로 로그인'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _toggleSignUpMode,
                  child: Text(
                    _isSignUp
                        ? '이미 계정이 있으신가요? 로그인'
                        : '계정이 없으신가요? 회원가입',
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

