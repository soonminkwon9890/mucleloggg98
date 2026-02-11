enum AppStatusType {
  upToDate,
  updateRequired,
  maintenance,
}

class AppStatus {
  final AppStatusType type;
  final String? message;
  final String? storeUrl;

  const AppStatus._(
    this.type, {
    this.message,
    this.storeUrl,
  });

  static const upToDate = AppStatus._(AppStatusType.upToDate);

  factory AppStatus.updateRequired(String storeUrl) =>
      AppStatus._(AppStatusType.updateRequired, storeUrl: storeUrl);

  factory AppStatus.maintenance(String message) =>
      AppStatus._(AppStatusType.maintenance, message: message);
}

