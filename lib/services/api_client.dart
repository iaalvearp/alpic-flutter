import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

abstract interface class ApiTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> delete();
}

class SecureApiTokenStore implements ApiTokenStore {
  SecureApiTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'alpics_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    ApiTokenStore? tokenStore,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? SecureApiTokenStore();

  final String _baseUrl;
  final http.Client _httpClient;
  final ApiTokenStore _tokenStore;

  Future<void> saveToken(String token) => _tokenStore.write(token);

  Future<void> clearToken() => _tokenStore.delete();

  Future<String?> readToken() => _tokenStore.read();

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: await _headers(),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: {...await _headers(), 'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _httpClient.put(
      _uri(path),
      headers: {...await _headers(), 'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<void> delete(String path) async {
    final response = await _httpClient.delete(
      _uri(path),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> postMultipart({
    required String path,
    required Map<String, String> fields,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers());
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decodeObject(response);
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStore.read();
    return {
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    _ensureSuccess(response);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 502,
        code: 'INVALID_API_RESPONSE',
        message: 'La API devolvió una respuesta inválida.',
      );
    }
    return decoded;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final decoded = jsonDecode(response.body);
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      if (error is Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          code: error['code'] as String? ?? 'HTTP_ERROR',
          message: error['message'] as String? ?? 'La API devolvió un error.',
          details: error['details'],
        );
      }
    } on ApiException {
      rethrow;
    } on Object {
      // Fall through to the generic HTTP error below.
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_ERROR',
      message: 'La API devolvió un error HTTP ${response.statusCode}.',
    );
  }
}
