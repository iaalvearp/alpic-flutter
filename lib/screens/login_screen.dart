import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/api_auth_service.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authService,
    required this.onAuthenticated,
    this.startupMessage,
    super.key,
  });

  final ApiAuthService authService;
  final ValueChanged<AuthSession> onAuthenticated;
  final String? startupMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isWorking) return;
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) widget.onAuthenticated(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'No fue posible iniciar sesión.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  String _friendlyError(ApiException error) {
    if (error.statusCode == 401) return 'Correo o contraseña incorrectos.';
    if (error.statusCode == 400) return error.message;
    return 'No fue posible conectar con el servidor.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AlPics')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Inicia sesión',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Accede a tus imágenes desde AlPics.'),
                    if (widget.startupMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.startupMessage!,
                        key: const Key('mensaje-inicio-sesion'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('campo-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Introduce un correo válido.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-password'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) => value == null || value.length < 8
                          ? 'La contraseña debe tener al menos 8 caracteres.'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        key: const Key('error-login'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('boton-login'),
                      onPressed: _isWorking ? null : _login,
                      child: _isWorking
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
