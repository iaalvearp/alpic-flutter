import 'package:flutter/material.dart';

import '../services/api_auth_service.dart';
import '../services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.authService, super.key});

  final ApiAuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _isWorking) return;
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'No fue posible crear la cuenta.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  String _friendlyError(ApiException error) {
    if (error.statusCode == 409) return 'Ese correo ya tiene una cuenta.';
    if (error.statusCode == 400) return error.message;
    return 'No fue posible conectar con el servidor.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                      'Crea tu cuenta',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Guarda y comparte tus fotos desde AlPics.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('campo-email-registro'),
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
                      key: const Key('campo-password-registro'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 8 caracteres.',
                      ),
                      validator: (value) => value == null || value.length < 8
                          ? 'La contraseña debe tener al menos 8 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-password-confirmacion'),
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                      ),
                      validator: (value) =>
                          value != _passwordController.text
                          ? 'Las contraseñas no coinciden.'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        key: const Key('error-registro'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('boton-registro'),
                      onPressed: _isWorking ? null : _register,
                      child: _isWorking
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
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