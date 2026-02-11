import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../data/services/supabase_service.dart';
import '../models/app_config.dart';
import '../../domain/models/app_status.dart';

class VersionRepository {
  const VersionRepository();

  Future<AppStatus> checkAppStatus() async {
    try {
      // 1) Supabase 조회 (single row)
      final data = await SupabaseService.client.from('app_config').select().single();
      final config = AppConfig.fromJson(Map<String, dynamic>.from(data));

      // 2) 점검 체크
      if (config.isMaintenance) {
        return AppStatus.maintenance(config.maintenanceMsg);
      }

      // 3) 버전 체크
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final String minVersionStr;
      final String storeUrl;

      if (kIsWeb) {
        // Closed beta 대상이 모바일이라면 web은 통과(또는 별도 정책 추가)
        return AppStatus.upToDate;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        minVersionStr = config.minVersionIos;
        storeUrl = config.storeUrlIos;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        minVersionStr = config.minVersionAndroid;
        storeUrl = config.storeUrlAndroid;
      } else {
        // macOS 등 데스크탑은 통과(또는 별도 정책 추가)
        return AppStatus.upToDate;
      }

      final minVersion = Version.parse(minVersionStr);

      if (currentVersion < minVersion) {
        return AppStatus.updateRequired(storeUrl);
      }

      return AppStatus.upToDate;
    } catch (e, st) {
      // 오프라인/네트워크/파싱 에러 등: 크래시 금지
      debugPrint('[VersionRepository] checkAppStatus failed: $e\n$st');
      return AppStatus.upToDate;
    }
  }
}

