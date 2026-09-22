import 'package:flutter/material.dart';

import 'app/alpics_app.dart';
import 'config/api_config.dart';
import 'models/auth_session.dart';
import 'repositories/rest_image_repository.dart';
import 'services/api_auth_service.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupMessage;
  final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  final authService = ApiAuthService(apiClient);
  AuthSession? session;
  try {
    session = await authService.restoreSession();
  } on ApiException catch (error) {
    debugPrint('REST session restore failed: $error');
    startupMessage = 'No pudimos validar tu sesión. Inicia sesión nuevamente.';
  } catch (error, stackTrace) {
    debugPrint('REST initialization failed: $error');
    debugPrint('Stack trace: $stackTrace');
    startupMessage = 'No pudimos conectarnos en este momento.';
  }

  runApp(
    AlPicsApp(
      authService: authService,
      startupMessage: startupMessage,
      initialSession: session,
      imageRepository: RestImageRepository(apiClient),
      authenticatedUserId: session?.user.id,
      authenticatedUserRole: session?.user.role,
      authenticatedUserEmail: session?.user.email,
    ),
  );
}
