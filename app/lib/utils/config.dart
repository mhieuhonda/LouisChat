// Central configuration. Edit API_URL / SOCKET_URL to point to your server.
// For Android emulator use http://10.0.2.2:3000; for a real device use a
// reachable LAN/public IP.

class AppConfig {
  // REST API base URL (no trailing slash)
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // Socket.io URL (usually same host as API)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // App identity
  static const String appName = 'LouisChat';
  static const String appVersion = '0.1.0';
}
