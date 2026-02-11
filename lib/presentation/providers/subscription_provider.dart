import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../../data/models/user_profile.dart';

/// 개발용 프리미엄 강제 모드 (릴리즈에서는 절대 동작하지 않음)
const bool forcePremiumDevMode = false;

class SubscriptionState {
  final bool isPremium;
  final bool isAdmin;
  final bool isFreeTrial;
  final bool hasCoupon;
  final bool isLoading;

  const SubscriptionState({
    required this.isPremium,
    required this.isAdmin,
    required this.isFreeTrial,
    required this.hasCoupon,
    required this.isLoading,
  });

  static const loading = SubscriptionState(
    isPremium: false,
    isAdmin: false,
    isFreeTrial: false,
    hasCoupon: false,
    isLoading: true,
  );
}

final subscriptionProvider = Provider<SubscriptionState>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);

  return profileAsync.when(
    data: (UserProfile? profile) {
      // 1) 개발자 강제 모드 (릴리즈에선 절대 동작 안 함)
      if (!kReleaseMode && forcePremiumDevMode) {
        return const SubscriptionState(
          isPremium: true,
          isAdmin: false,
          isFreeTrial: false,
          hasCoupon: false,
          isLoading: false,
        );
      }

      final isAdmin = profile?.isAdmin == true;
      final nowUtc = DateTime.now().toUtc();

      // isPremium: 오직 (profile.isPremium == true && premiumUntil > now UTC) 일 때만 true
      final expiration = profile?.premiumUntil?.toUtc();
      final isPremium = profile?.isPremium == true &&
          expiration != null &&
          expiration.isAfter(nowUtc);

      // 쿠폰 기반 수동 체험으로 전환: 자동 isFreeTrial 제거. (표시용으로 false 유지)
      const isFreeTrial = false;

      final hasCoupon = profile?.isCouponAvailable ?? false;

      return SubscriptionState(
        isPremium: isPremium,
        isAdmin: isAdmin,
        isFreeTrial: isFreeTrial,
        hasCoupon: hasCoupon,
        isLoading: false,
      );
    },
    loading: () => SubscriptionState.loading,
    error: (_, __) => const SubscriptionState(
      isPremium: false,
      isAdmin: false,
      isFreeTrial: false,
      hasCoupon: false,
      isLoading: false,
    ),
  );
});

