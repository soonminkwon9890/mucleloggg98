import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../admin/admin_screen.dart';
import '../subscription/subscription_screen.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _isProcessing = false;
  bool _isActivatingCoupon = false;

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
      ref.invalidate(currentProfileProvider);
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
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 삭제 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _activateCoupon() async {
    if (_isActivatingCoupon) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('쿠폰 사용'),
        content: const Text(
          '지금 사용하시겠습니까? 사용 즉시 7일이 시작됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isActivatingCoupon = true);
    try {
      await ref.read(userRepositoryProvider).activateCoupon();
      if (!mounted) return;
      // ignore: unused_result
      ref.refresh(currentProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('7일 체험이 시작되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActivatingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('로그인이 필요합니다.'))
            : RefreshIndicator(
                onRefresh: () async {
                  // ignore: unused_result
                  ref.refresh(currentProfileProvider);
                  await ref.read(currentProfileProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      if (!subscription.isPremium && subscription.hasCoupon) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '신규 회원 7일 무료 체험 쿠폰이 있습니다!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _isActivatingCoupon
                                        ? null
                                        : _activateCoupon,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                    icon: _isActivatingCoupon
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.card_giftcard),
                                    label: Text(
                                      _isActivatingCoupon
                                          ? '처리 중...'
                                          : '쿠폰 사용하기',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Card(
                        child: ListTile(
                          title: const Text(
                            '멤버십 관리',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('구독 상태 확인 및 쿠폰 안내'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          title: const Text(
                            'Premium 멤버십 가입하기',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('더 많은 기능을 사용해보세요.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          );
                          },
                        ),
                      ),
                      if (subscription.isAdmin) ...[
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            title: const Text(
                              'Admin Menu',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('프리미엄 권한 부여'),
                            trailing: const Icon(Icons.admin_panel_settings),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _TesterIdRow(userId: user.id),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _TesterIdRow extends StatelessWidget {
  const _TesterIdRow({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final displayId = userId.length >= 8 ? '${userId.substring(0, 8)}...' : userId;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테스터 ID (복사하여 개발자에게 전달):',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                displayId,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID가 복사되었습니다. 개발자에게 전달해 주세요.'),
              ),
            );
          },
          tooltip: 'ID 복사',
        ),
      ],
    );
  }
}

