class AppConfig {
  final String minVersionIos;
  final String minVersionAndroid;
  final bool isMaintenance;
  final String maintenanceMsg;
  final String storeUrlIos;
  final String storeUrlAndroid;

  const AppConfig({
    required this.minVersionIos,
    required this.minVersionAndroid,
    required this.isMaintenance,
    required this.maintenanceMsg,
    required this.storeUrlIos,
    required this.storeUrlAndroid,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      minVersionIos: (json['min_version_ios'] as String?)?.trim() ?? '0.0.0',
      minVersionAndroid:
          (json['min_version_android'] as String?)?.trim() ?? '0.0.0',
      isMaintenance: (json['is_maintenance'] as bool?) ?? false,
      maintenanceMsg: (json['maintenance_msg'] as String?)?.trim() ?? '점검 중입니다.',
      storeUrlIos: (json['store_url_ios'] as String?)?.trim() ?? '',
      storeUrlAndroid: (json['store_url_android'] as String?)?.trim() ?? '',
    );
  }
}

