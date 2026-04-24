/// 앱 전역 기능 플래그 설정
///
/// 이 파일은 앱의 기능 토글을 관리합니다.
/// 결제 시스템을 활성화하려면 [isPaymentEnabled]를 true로 변경하세요.
class AppConfig {
  AppConfig._();

  /// 결제/구독 시스템 활성화 여부
  ///
  /// - `false`: 출시 기념 이벤트 모드 - 모든 프리미엄 기능 무료 제공
  ///   - 결제 UI 숨김 (멤버십 관리, 프리미엄 가입 메뉴 등)
  ///   - 쿠폰 섹션 숨김
  ///   - 모든 프리미엄 기능 접근 허용 (루틴 개수 무제한, AI 분석 등)
  ///
  /// - `true`: 정식 런칭 모드 - 기존 프리미엄 모델 활성화
  ///   - 결제 UI 표시
  ///   - 프리미엄/무료 사용자 구분
  ///   - 기능 제한 적용
  static const bool isPaymentEnabled = false;

  /// 출시 기념 이벤트 안내 메시지
  static const String betaFreeMessage =
      '출시 기념 이벤트 기간 동안 모든 기능을 무료로 제공합니다! 🎁';
}
