import '../models/auth_session.dart';
import 'api_client.dart';

class ApiAuthService {
  const ApiAuthService(this._client);

  final ApiClient _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return _parseSession(response);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.postJson('/api/auth/register', {
      'email': email,
      'password': password,
    });
    return _parseSession(response);
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _client.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _client.getJson('/api/auth/me');
      final data = _data(response);
      return AuthSession(user: AuthUser.fromJson(data), accessToken: token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _client.clearToken();
      rethrow;
    }
  }

  Future<void> logout() => _client.clearToken();

  Future<AuthSession> _parseSession(Map<String, dynamic> response) async {
    final data = _data(response);
    final token = data['accessToken'] as String;
    await _client.saveToken(token);
    return AuthSession(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: token,
      expiresAt: (data['expiresAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 502,
        code: 'INVALID_API_RESPONSE',
        message: 'La API devolvió una respuesta inválida.',
      );
    }
    return data;
  }
}
