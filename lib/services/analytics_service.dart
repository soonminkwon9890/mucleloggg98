import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/config/env_config.dart';

/// Dual-Tracking 분석 서비스 싱글턴 래퍼 (Amplitude v4 + Firebase Analytics GA4).
///
/// 사용법:
///   1. `main()` 에서 Firebase.initializeApp() 후 `AnalyticsService().init()` 호출
///   2. 이벤트 추적: `await AnalyticsService().trackEvent('event_name', properties: {...})`
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late final Amplitude amplitude;
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;

  void init() {
    // AMPLITUDE_API_KEY 는 빌드 시 --dart-define-from-file=config.json 으로 주입됩니다.
    // 빈 문자열이면 config.json 없이 빌드된 것이므로 즉시 에러를 발생시켜 누락을 조기에 감지합니다.
    assert(
      EnvConfig.amplitudeApiKey.isNotEmpty,
      'AMPLITUDE_API_KEY가 비어 있습니다. '
      '--dart-define-from-file=config.json 옵션으로 빌드하세요.',
    );
    amplitude = Amplitude(Configuration(
      apiKey: EnvConfig.amplitudeApiKey,
    ));
  }

  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    // 1. Amplitude로 전송
    amplitude.track(BaseEvent(eventName, eventProperties: properties));

    // 2. Firebase Analytics (GA4)로 전송
    // Firebase는 String, int, double, bool 타입만 허용하므로 필터링
    final Map<String, Object>? firebaseParams = properties?.map(
      (key, value) {
        if (value is String || value is int || value is double || value is bool) {
          return MapEntry(key, value as Object);
        }
        return MapEntry(key, value.toString());
      },
    );
    await _firebaseAnalytics.logEvent(
      name: eventName,
      parameters: firebaseParams,
    );
  }
}
