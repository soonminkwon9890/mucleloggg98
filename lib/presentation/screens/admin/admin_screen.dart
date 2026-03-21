import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

/// 관리자 권한 전용 접근 제어 위젯.
///
/// UserProfile.isAdmin 이 true 가 아닌 사용자에게는 어드민 UI를 일절 렌더링하지 않습니다.
/// Supabase RLS 가 백엔드 1차 방어선이고, 이 위젯이 클라이언트 2차 방어선입니다.
class _AdminGuard extends ConsumerWidget {
  final Widget child;
  const _AdminGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _accessDeniedScaffold(context),
      data: (profile) {
        if (profile?.isAdmin != true) {
          return _accessDeniedScaffold(context);
        }
        return child;
      },
    );
  }

  Widget _accessDeniedScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('접근 거부')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '접근 권한이 없습니다.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            const Text('관리자 계정으로 로그인하세요.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _targetIdController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _targetIdController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _targetIdController.text = text;
  }

  Future<void> _revokePremium() async {
    if (_isProcessing) return;
    final targetId = _targetIdController.text.trim();
    if (targetId.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(userRepositoryProvider).revokePremium(targetId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프리미엄 해제됨'),
          backgroundColor: Colors.green,
        ),
      );

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null && currentUserId == targetId) {
        ref.invalidate(currentProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _grantPremium(int days) async {
    if (_isProcessing) return;
    final targetId = _targetIdController.text.trim();
    if (targetId.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(userRepositoryProvider).grantPremium(targetId, days);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프리미엄 $days일 부여 완료'),
          backgroundColor: Colors.green,
        ),
      );

      // 관리자가 본인에게 권한을 부여한 경우 즉시 반영
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null && currentUserId == targetId) {
        ref.invalidate(currentProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminGuard(
      child: _buildAdminUi(context),
    );
  }

  Widget _buildAdminUi(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetIdController,
                      decoration: const InputDecoration(
                        labelText: 'Target User UUID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Paste',
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _grantPremium(30),
                child: const Text('Grant 30 Days'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _grantPremium(365),
                child: const Text('Grant 365 Days'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _revokePremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Revoke Premium (프리미엄 해제)'),
              ),
              const SizedBox(height: 12),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

