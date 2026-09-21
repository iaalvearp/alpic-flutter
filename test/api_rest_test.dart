import 'dart:convert';
import 'dart:typed_data';

import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/repositories/rest_image_repository.dart';
import 'package:alpic_flutter/services/api_auth_service.dart';
import 'package:alpic_flutter/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login stores the JWT and sends it on subsequent requests', () async {
    final tokenStore = _MemoryTokenStore();
    final client = _ApiTestClient((request) {
      if (request.method == 'POST' && request.url.path == '/api/auth/login') {
        return _jsonResponse({
          'data': {
            'user': {
              'id': 'user-1',
              'email': 'user@example.com',
              'createdAt': null,
              'role': 'USER',
            },
            'accessToken': 'jwt-token',
            'tokenType': 'Bearer',
            'expiresAt': null,
          },
        });
      }
      expect(request.headers['authorization'], 'Bearer jwt-token');
      return _jsonResponse({
        'data': {'ok': true},
      });
    });
    final apiClient = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: client,
      tokenStore: tokenStore,
    );
    final auth = ApiAuthService(apiClient);

    final session = await auth.login(
      email: 'user@example.com',
      password: 'correct-password',
    );
    await apiClient.getJson('/api/auth/me');

    expect(session.user.id, 'user-1');
    expect(tokenStore.value, 'jwt-token');
    expect(client.requests.map((request) => request.method), ['POST', 'GET']);
  });

  test('HTTP errors preserve the backend JSON error contract', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: _ApiTestClient(
        (_) => _jsonResponse({
          'error': {'code': 'IMAGE_NOT_FOUND', 'message': 'Image not found'},
        }, statusCode: 404),
      ),
      tokenStore: _MemoryTokenStore(),
    );

    await expectLater(
      apiClient.getJson('/api/images/missing'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 404)
            .having((error) => error.code, 'code', 'IMAGE_NOT_FOUND'),
      ),
    );
  });

  test('REST repository delegates image CRUD to the API', () async {
    final tokenStore = _MemoryTokenStore()..value = 'jwt-token';
    final client = _ApiTestClient((request) {
      expect(request.headers['authorization'], 'Bearer jwt-token');
      if (request.method == 'GET') {
        return _jsonResponse({
          'data': [_apiImageJson()],
        });
      }
      if (request.method == 'POST') {
        return _jsonResponse({'data': _apiImageJson()});
      }
      if (request.method == 'PUT') {
        return _jsonResponse({
          'data': {..._apiImageJson(), 'name': 'Editada'},
        });
      }
      return _jsonResponse({
        'data': {'id': 'image-1', 'deleted': true},
      });
    });
    final repository = RestImageRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: client,
        tokenStore: tokenStore,
      ),
    );

    final loaded = await repository.loadVisible();
    final uploaded = await repository.upload(_localImage());
    final edited = await repository.updateMetadata(
      uploaded.copyWith(name: 'Editada'),
    );
    await repository.softDelete(edited);

    expect(loaded.single.id, 'image-1');
    expect(uploaded.id, 'image-1');
    expect(edited.name, 'Editada');
    expect(client.requests.map((request) => request.method), [
      'GET',
      'POST',
      'PUT',
      'DELETE',
    ]);
  });
}

Map<String, dynamic> _apiImageJson() => {
  'id': 'image-1',
  'ownerId': 'user-1',
  'name': 'Imagen',
  'src': 'https://example.test/image.png',
  'storagePath': 'user-1/image-1.png',
  'alt': 'Alt',
  'description': 'Descripción',
  'mimeType': 'image/png',
  'extension': 'png',
  'sizeBytes': 3,
  'latitude': -0.18,
  'longitude': -78.48,
  'mapsUrl': null,
  'source': 'gallery',
  'originalFilename': 'foto.png',
  'createdAt': '2026-09-21T12:00:00.000Z',
  'updatedAt': '2026-09-21T12:00:00.000Z',
  'isVisible': true,
  'deletedAt': null,
};

ImageRecord _localImage() => ImageRecord(
  name: 'Imagen',
  alt: 'Alt',
  description: 'Descripción',
  mimeType: 'image/png',
  extension: 'png',
  sizeBytes: 3,
  source: ImageRecordSource.gallery,
  originalFilename: 'foto.png',
  createdAt: DateTime.utc(2026, 9, 21),
  updatedAt: DateTime.utc(2026, 9, 21),
  localFile: XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    name: 'foto.png',
    mimeType: 'image/png',
  ),
);

http.Response _jsonResponse(Object body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );

class _MemoryTokenStore implements ApiTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

class _ApiTestClient extends http.BaseClient {
  _ApiTestClient(this.handler);

  final http.Response Function(http.BaseRequest request) handler;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
