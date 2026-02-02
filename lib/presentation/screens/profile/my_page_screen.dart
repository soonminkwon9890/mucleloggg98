import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _isProcessing = false;

  String _displayName(User user) {
    final meta = user.userMetadata ?? {};
    final name = meta['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    return (email != null && email.isNotEmpty) ? email : '사용자';
  }

  Future<void> _signOut() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      // StreamBuilder 기반 자동 전환 시, 화면 스택을 먼저 정리하는 게 안전합니다.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    if (_isProcessing) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('모든 데이터가 영구 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      // 화면 스택을 먼저 정리해 StreamBuilder 전환 시 충돌 가능성 감소
      Navigator.of(context).popUntil((route) => route.isFirst);

      await ref.read(authRepositoryProvider).deleteAccount(user.id);

      // delete_user_account(RPC) 이후에도 로컬 세션 토큰이 남을 수 있으니 signOut으로 정리
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 삭제 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('로그인이 필요합니다.'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_displayName(user)}님 MUSCLELOG에 오신 것을 환영합니다',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        title: const Text(
                          'Premium 멤버십 가입하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('더 많은 기능을 사용해보세요.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: 결제/구독 연결
                        },
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '이용 약관 | 개인정보 처리방침',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _signOut,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('로그아웃'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isProcessing ? null : _confirmAndDeleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('계정 삭제'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

