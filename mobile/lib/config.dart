/// Application configuration.
///
/// The API base URL can be overridden at build/run time without code changes:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
///
/// Default is 10.0.2.2, which is how the Android emulator reaches the host
/// machine's localhost (where the Node backend runs on port 3000).
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Fallback coordinates (Nairobi) used when location permission is denied,
  /// so the user can still see sample nearby providers. This satisfies the
  /// "handle location-permission denial gracefully" requirement.
  static const double fallbackLatitude = -1.2641;
  static const double fallbackLongitude = 36.8028;
}
