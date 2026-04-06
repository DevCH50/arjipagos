import 'dart:io';

import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página completa para solicitar el restablecimiento de contraseña.
///
/// Reemplaza al antiguo diálogo para evitar problemas de teclado/overflow
/// en dispositivos con pantallas pequeñas o teclados flotantes.
/// Reutiliza el [LoginBloc] inyectado desde la pantalla de login.
class RecuperarContrasenaPage extends StatefulWidget {
  const RecuperarContrasenaPage({super.key});

  @override
  State<RecuperarContrasenaPage> createState() =>
      _RecuperarContrasenaPageState();
}

class _RecuperarContrasenaPageState extends State<RecuperarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  /// Mensaje de error del servidor. null = sin error.
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Detecta el nombre del dispositivo según la plataforma.
  String _getDeviceName() {
    if (Platform.isAndroid) {
      return 'Android';
    }
    if (Platform.isIOS) {
      return 'iOS';
    }
    return 'Mobile';
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _errorMessage = null);

    context.read<LoginBloc>().add(
          RecuperarContrasenaSubmitted(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            deviceName: _getDeviceName(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (prev, curr) =>
          prev.recuperarResponse != curr.recuperarResponse,
      listener: (context, state) {
        if (state.recuperarResponse is Error) {
          setState(() {
            _errorMessage = (state.recuperarResponse as Error).msg;
          });
          context.read<LoginBloc>().add(const RecuperarContrasenaReset());
        }
      },
      buildWhen: (prev, curr) =>
          prev.recuperarResponse != curr.recuperarResponse,
      builder: (context, state) {
        final isLoading = state.recuperarResponse is Loading;
        final isSuccess = state.recuperarResponse is Success;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isSuccess ? 'Correo enviado' : 'Recuperar contraseña',
            ),
            // Evita que el botón atrás quede activo durante la carga
            leading: isLoading
                ? const SizedBox.shrink()
                : BackButton(
                    onPressed: () {
                      context
                          .read<LoginBloc>()
                          .add(const RecuperarContrasenaReset());
                      Navigator.of(context).pop();
                    },
                  ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: isSuccess
                  ? _buildSuccess(context, colorScheme, textTheme)
                  : _buildForm(context, colorScheme, textTheme, isLoading),
            ),
          ),
        );
      },
    );
  }

  /// Vista de confirmación tras el envío exitoso.
  Widget _buildSuccess(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.mark_email_read_outlined,
          color: colorScheme.primary,
          size: 72,
        ),
        const SizedBox(height: 24),
        Text(
          'Revisa tu bandeja de entrada',
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Hemos enviado las instrucciones para recuperar tu contraseña al correo proporcionado.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              context
                  .read<LoginBloc>()
                  .add(const RecuperarContrasenaReset());
              Navigator.of(context).pop();
            },
            child: const Text('Aceptar'),
          ),
        ),
      ],
    );
  }

  /// Formulario de usuario y correo.
  Widget _buildForm(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            color: colorScheme.primary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa tu usuario y correo registrado. Te enviaremos instrucciones para restablecer tu contraseña.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _usernameController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu nombre de usuario';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          // Mensaje de error del servidor
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : () => _submit(context),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Enviar'),
            ),
          ),
        ],
      ),
    );
  }
}
