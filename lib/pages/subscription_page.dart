import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

/// RevenueCat 구독 화면 (iOS 클로즈 베타용)
/// 사용자에게 구독 옵션을 보여주고 구매/복원 기능 제공
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독하기'),
        centerTitle: true,
      ),
      body: FutureBuilder<Offerings?>(
        future: RevenueCatService.instance.getOfferings(),
        builder: (context, snapshot) {
          // 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 에러 또는 데이터 없음
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '구독 상품을 불러올 수 없습니다',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}), // 재시도
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 오퍼링 데이터 가져오기
          final offering = snapshot.data!.getOffering('default');
          if (offering == null || offering.availablePackages.isEmpty) {
            return const Center(
              child: Text('사용 가능한 구독 상품이 없습니다'),
            );
          }

          final packages = offering.availablePackages;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 헤더
                    const Text(
                      'MuscleLog Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI 기반 운동 분석과 무제한 기록',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 패키지 카드 리스트
                    ...packages.map((package) => _buildPackageCard(package)),

                    const SizedBox(height: 32),
                    
                    // 이용 약관 등
                    const Text(
                      '• 구독은 자동으로 갱신됩니다\n'
                      '• 취소는 앱스토어 구독 관리에서 가능합니다\n'
                      '• 구독 시 이용 약관 및 개인정보 처리방침에 동의하게 됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 구매 복원 버튼 (하단 고정)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: TextButton(
                    onPressed: _isProcessing ? null : _handleRestore,
                    child: const Text(
                      '구매 복원',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 패키지 카드 UI
  Widget _buildPackageCard(Package package) {
    final product = package.storeProduct;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품명
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 가격
            Text(
              product.priceString,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // 설명
            Text(
              product.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // 구독하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _handlePurchase(package),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '구독하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 패키지 구매 처리
  Future<void> _handlePurchase(Package package) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await RevenueCatService.instance.purchasePackage(package);
      
      if (!mounted) return;

      if (success && RevenueCatService.instance.isPro) {
        // 성공: Snackbar 표시 후 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독이 완료되었습니다! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 잠시 대기 후 화면 닫기
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // 실패 또는 구독 확인 실패
        _showError('구독 처리 중 문제가 발생했습니다');
      }
    } catch (e) {
      if (mounted) {
        _showError('구독 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 구매 복원 처리
  Future<void> _handleRestore() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await RevenueCatService.instance.restorePurchases();
      
      if (!mounted) return;

      if (success && RevenueCatService.instance.isPro) {
        // 복원 성공: Snackbar 표시 후 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독이 복원되었습니다! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // 복원할 구매 내역이 없음
        _showError('복원할 구독 내역이 없습니다');
      }
    } catch (e) {
      if (mounted) {
        _showError('복원 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 에러 메시지 표시
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
