// Central configuration.
// The server URL is runtime-configurable (stored in SharedPreferences) so the
// user can change it inside the app without recompiling.

class AppConfig {
  // Default server URL. Override at runtime via Settings screen.
  // For Android emulator use http://10.0.2.2:3000
  // For real device use a reachable LAN/public IP.
  static const String defaultApiUrl = 'http://163.44.96.79:3000';
  static const String defaultSocketUrl = 'http://163.44.96.79:3000';

  // SharedPreferences keys
  static const String kApiUrl = 'server_api_url';
  static const String kSocketUrl = 'server_socket_url';

  // App identity
  static const String appName = 'LouisChat';
  static const String appVersion = '0.2.0';
}
