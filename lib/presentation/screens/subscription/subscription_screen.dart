import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';

/// 구독(멤버십) 상태 확인 화면. 클로즈 베타용.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버십 관리'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(currentProfileProvider);
          await ref.read(currentProfileProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: profileAsync.when(
            data: (profile) {
              return _buildContent(
                context,
                isPremium: subscription.isPremium,
                premiumUntil: profile?.premiumUntil,
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('로딩 실패: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isPremium,
    DateTime? premiumUntil,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusCard(context, isPremium: isPremium, premiumUntil: premiumUntil),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '현재 클로즈 베타 테스트 기간입니다. 결제 기능은 추후 업데이트될 예정입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            // TODO: 실제 결제 구현 시
            // RevenueCat 결제 완료 콜백에서 Navigator.pop(context, true) 호출하여
            // 호출부(showPremiumGuidanceDialog)에 결제 성공 여부 전달
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('베타 기간에는 무료 쿠폰을 이용해주세요!'),
              ),
            );
            // 결제 성공 예시:
            // if (paymentSuccess) {
            //   Navigator.pop(context, true);
            // }
          },
          child: const Text('월간 구독 (Coming Soon)'),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required bool isPremium,
    DateTime? premiumUntil,
  }) {
    if (isPremium) {
      final localUntil = premiumUntil?.toLocal();
      final validUntilStr = localUntil != null
          ? '${DateFormat('y년 M월 d일', 'ko_KR').format(localUntil)}까지 유효'
          : null;

      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Premium 멤버십 사용 중',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (validUntilStr != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        validUntilStr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Chip(
                label: Text('Active'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic 멤버십 (현재 체험 중이 아닙니다)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // 쿠폰 적용 화면(마이페이지)으로 이동하므로 단순 pop
                // 쿠폰 적용 성공 시 프로필 갱신되면 다음 진입 시 isPremium=true 표시
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('마이페이지에서 쿠폰을 사용해주세요'),
                  ),
                );
              },
              child: const Text('베타 쿠폰 쓰러가기'),
            ),
          ],
        ),
      ),
    );
  }
}
