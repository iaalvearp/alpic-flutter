abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'ALPICS_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
}
