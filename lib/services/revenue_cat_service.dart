import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RevenueCat 구독 관리 서비스 (iOS 클로즈 베타용)
/// Singleton 패턴으로 앱 전역에서 접근 가능
class RevenueCatService {
  // Singleton
  static final RevenueCatService _instance = RevenueCatService._();
  static RevenueCatService get instance => _instance;
  
  RevenueCatService._();

  // 상수 (오타 방지)
  static const String _entitlementId = 'musclelog Pro'; // 공백 포함
  static const String _offeringId = 'default';
  static const String _iosApiKey = 'appl_rXcLrmhBGfZPjkWxyTvnrBukATz';

  // 캐싱 및 상태 관리
  Offerings? _cachedOfferings;
  bool _isPro = false;
  final StreamController<bool> _entitlementController = 
      StreamController<bool>.broadcast();

  /// 현재 구독 상태 (동기적 접근)
  bool get isPro => _isPro;

  /// 구독 상태 변화 스트림 (비동기 접근)
  Stream<bool> get entitlementStream => _entitlementController.stream;

  /// RevenueCat SDK 초기화
  /// - iOS에서만 실행
  /// - Supabase Auth 상태와 연동
  /// - 초기 구독 상태 로드
  Future<void> init() async {
    try {
      // Platform Guard: Android에서는 아무것도 하지 않음
      if (!Platform.isIOS) return;

      // Configure RevenueCat
      await Purchases.configure(
        PurchasesConfiguration(_iosApiKey),
      );

      // Debug 로그 활성화
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Supabase Auth 리스너 (캡슐화)
      Supabase.instance.client.auth.onAuthStateChange.listen((AuthState data) {
        try {
          if (data.session != null) {
            // 로그인 시: RevenueCat에 사용자 등록
            Purchases.logIn(data.session!.user.id);
          } else {
            // 로그아웃 시: RevenueCat 사용자 해제
            Purchases.logOut();
          }
        } catch (e) {
          debugPrint('RevenueCat Auth sync error: $e');
        }
      });

      // 초기 구독 상태 로드
      await _loadInitialEntitlementStatus();

      // CustomerInfo 변경 리스너 등록
      Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
        _updateEntitlementStatus(info);
      });

      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  /// 초기 구독 상태를 로드하여 _isPro와 Stream에 반영
  Future<void> _loadInitialEntitlementStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlementStatus(customerInfo);
    } catch (e) {
      debugPrint('Failed to load initial entitlement status: $e');
    }
  }

  /// CustomerInfo를 기반으로 _isPro 갱신 및 Stream emit
  void _updateEntitlementStatus(CustomerInfo info) {
    final isActive = 
        info.entitlements.all[_entitlementId]?.isActive == true;
    
    if (_isPro != isActive) {
      _isPro = isActive;
      _entitlementController.add(_isPro);
      debugPrint('RevenueCat entitlement status updated: $_isPro');
    }
  }

  /// 오퍼링 조회 (캐싱 적용)
  /// 1. Platform 체크
  /// 2. 캐시 반환
  /// 3. Fetch & 캐시 저장
  /// 4. 에러 시 null
  Future<Offerings?> getOfferings() async {
    try {
      // 1. Platform Guard
      if (!Platform.isIOS) return null;

      // 2. 캐시 확인
      if (_cachedOfferings != null) {
        return _cachedOfferings;
      }

      // 3. Fetch & 캐시 저장
      final offerings = await Purchases.getOfferings();
      _cachedOfferings = offerings.getOffering(_offeringId) != null
          ? offerings
          : null;
      
      return _cachedOfferings;
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return null;
    }
  }

  /// 패키지 구매
  /// 성공 시 _isPro 갱신 및 Stream emit 후 true 반환
  Future<bool> purchasePackage(Package package) async {
    try {
      // 신규 API: PurchaseParams.package() 사용
      final purchaseParams = PurchaseParams.package(package);
      await Purchases.purchase(purchaseParams);

      // 성공 시 권한 확인 및 상태 갱신
      final customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlementStatus(customerInfo);

      return _isPro;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  /// 구매 복원
  /// 성공 시 _isPro 갱신 및 Stream emit 후 true 반환
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      
      // 성공 시 권한 확인 및 상태 갱신
      _updateEntitlementStatus(customerInfo);
      
      return _isPro;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  /// 리소스 정리 (앱 종료 시 호출 가능)
  void dispose() {
    _entitlementController.close();
  }
}
