class ZegoCallConfig {
  const ZegoCallConfig._();

  /// Prefer set via `--dart-define=ZEGO_APP_ID=...`
  static const int appID = int.fromEnvironment('ZEGO_APP_ID', defaultValue: 0);

  /// Optional (for offline call invitation / ringtone).
  /// Set via `--dart-define=ZEGO_CALL_RESOURCE_ID=...`
  static const String callResourceID =
      String.fromEnvironment('ZEGO_CALL_RESOURCE_ID', defaultValue: '');
}
