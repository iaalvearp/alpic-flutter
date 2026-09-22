import 'dart:convert';

import 'package:alpic_flutter/models/auth_session.dart';
import 'package:alpic_flutter/screens/login_screen.dart';
import 'package:alpic_flutter/screens/register_screen.dart';
import 'package:alpic_flutter/services/api_auth_service.dart';
import 'package:alpic_flutter/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('la pantalla de login obtiene y almacena la sesión REST', (
    tester,
  ) async {
    final tokenStore = _MemoryTokenStore();
    AuthSession? session;
    final authService = ApiAuthService(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: _LoginHttpClient(),
        tokenStore: tokenStore,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: authService,
          onAuthenticated: (value) => session = value,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('campo-email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('campo-password')),
      'correct-password',
    );
    await tester.tap(find.byKey(const Key('boton-login')));
    await tester.pumpAndSettle();

    expect(session?.user.id, 'user-1');
    expect(tokenStore.value, 'jwt-token');
  });

  testWidgets('el login muestra el logo y el enlace para crear una cuenta', (
    tester,
  ) async {
    final authService = ApiAuthService(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: _LoginHttpClient(),
        tokenStore: _MemoryTokenStore(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: authService,
          onAuthenticated: (_) {},
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const Key('boton-crear-cuenta')), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Crea una'), findsOneWidget);
  });

  testWidgets('el registro valida que las contraseñas coincidan', (
    tester,
  ) async {
    final authService = ApiAuthService(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: _LoginHttpClient(),
        tokenStore: _MemoryTokenStore(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(authService: authService)),
    );

    await tester.enterText(
      find.byKey(const Key('campo-email-registro')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('campo-password-registro')),
      'correct-password',
    );
    await tester.enterText(
      find.byKey(const Key('campo-password-confirmacion')),
      'different-password',
    );
    await tester.tap(find.byKey(const Key('boton-registro')));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}

class _MemoryTokenStore implements ApiTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

class _LoginHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({
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
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}
