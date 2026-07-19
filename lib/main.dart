import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/alpics_app.dart';
import 'config/supabase_config.dart';
import 'repositories/image_repository.dart';
import 'services/auth_service.dart';
import 'services/image_remote_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupMessage;
  String? authenticatedUserId;
  ImageRepository? imageRepository;
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      publishableKey: SupabaseConfig.publishableKey,
    );
    debugPrint('Supabase initialized');
    final authenticatedImageRepository = SupabaseImageRepository(
      SupabaseImageRemoteGateway(Supabase.instance.client),
    );

    final authDiagnostic = await AuthService(
      Supabase.instance.client,
    ).ensureAnonymousSession();
    if (authDiagnostic.state == AuthDiagnosticState.error) {
      startupMessage =
          'No pudimos conectarnos en este momento. Puedes seguir usando la aplicación.';
    } else {
      authenticatedUserId = authDiagnostic.userId;
      imageRepository = authenticatedImageRepository;
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Authentication failure: Supabase initialization failed: $error',
    );
    debugPrint('Stack trace: $stackTrace');
    startupMessage =
        'No pudimos conectarnos en este momento. Puedes seguir usando la aplicación.';
  }

  runApp(
    AlPicsApp(
      startupMessage: startupMessage,
      imageRepository: imageRepository,
      authenticatedUserId: authenticatedUserId,
    ),
  );
}
