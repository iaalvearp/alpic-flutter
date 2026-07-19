import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthDiagnosticState {
  checking,
  existingSessionValid,
  anonymousUserCreated,
  error,
}

class AuthDiagnosticResult {
  const AuthDiagnosticResult({
    required this.state,
    this.userId,
    this.errorMessage,
  });

  const AuthDiagnosticResult.checking()
    : state = AuthDiagnosticState.checking,
      userId = null,
      errorMessage = null;

  final AuthDiagnosticState state;
  final String? userId;
  final String? errorMessage;

  String get displayText {
    final shortUserId = userId?.substring(
      0,
      userId!.length < 8 ? userId!.length : 8,
    );
    return switch (state) {
      AuthDiagnosticState.checking => 'Auth: checking',
      AuthDiagnosticState.existingSessionValid =>
        'Auth: existing session valid · $shortUserId',
      AuthDiagnosticState.anonymousUserCreated =>
        'Auth: anonymous user created · $shortUserId',
      AuthDiagnosticState.error => 'Auth error: $errorMessage',
    };
  }
}

class AuthService {
  const AuthService(this._client);

  final SupabaseClient _client;

  Future<AuthDiagnosticResult> ensureAnonymousSession() async {
    if (_client.auth.currentSession != null) {
      _log('Previous session found; validating user');
      try {
        final response = await _client.auth.getUser();
        final user = response.user;
        if (user != null) {
          _log('Existing session valid; user ID: ${user.id}');
          return AuthDiagnosticResult(
            state: AuthDiagnosticState.existingSessionValid,
            userId: user.id,
          );
        }
        _log('Existing session invalid: no user returned');
      } on AuthException catch (error) {
        _logAuthException('Existing session validation failed', error);
      } catch (error, stackTrace) {
        _logUnexpected('Existing session validation failed', error, stackTrace);
      }

      try {
        await _client.auth.signOut(scope: SignOutScope.local);
        _log('Invalid local session cleared');
      } on AuthException catch (error) {
        _logAuthException('Local sign-out failed', error);
      } catch (error, stackTrace) {
        _logUnexpected('Local sign-out failed', error, stackTrace);
      }
    }

    _log('Anonymous sign-in started');
    try {
      final response = await _client.auth.signInAnonymously();
      _log('Anonymous sign-in response received');

      final user = response.user;
      final session = response.session;
      _log('Returned user ID: ${user?.id}');
      _log('Returned session present: ${session != null}');

      if (user == null || session == null) {
        const message = 'incomplete authentication response';
        _log('Authentication failure: $message');
        return const AuthDiagnosticResult(
          state: AuthDiagnosticState.error,
          errorMessage: message,
        );
      }

      _log('Anonymous session created');
      return AuthDiagnosticResult(
        state: AuthDiagnosticState.anonymousUserCreated,
        userId: user.id,
      );
    } on AuthException catch (error) {
      _logAuthException('Anonymous sign-in failed', error);
      return AuthDiagnosticResult(
        state: AuthDiagnosticState.error,
        errorMessage: _shortMessage(error.message),
      );
    } catch (error, stackTrace) {
      _logUnexpected('Anonymous sign-in failed', error, stackTrace);
      return AuthDiagnosticResult(
        state: AuthDiagnosticState.error,
        errorMessage: _shortMessage(error.toString()),
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  void _logAuthException(String context, AuthException error) {
    _log(
      '$context: message=${error.message}, '
      'statusCode=${error.statusCode}, code=${error.code}',
    );
  }

  void _logUnexpected(String context, Object error, StackTrace stackTrace) {
    _log('$context: $error');
    _log('Stack trace: $stackTrace');
  }

  String _shortMessage(String message) {
    final singleLine = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 80) return singleLine;
    return '${singleLine.substring(0, 77)}...';
  }
}
