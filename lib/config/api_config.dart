abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'ALPICS_API_BASE_URL',
    defaultValue: 'https://alpic-backend.iaalvearp.workers.dev',
  );
}
