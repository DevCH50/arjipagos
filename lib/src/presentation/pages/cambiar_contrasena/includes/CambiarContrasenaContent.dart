import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:arjipagos/src/presentation/widgets/DefaultTextField.dart';
import 'package:arjipagos/src/presentation/widgets/PrimaryElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que contiene el formulario de cambio de contraseña.
///
/// Muestra los campos de contraseña actual, contraseña nueva
/// y confirmación. Valida en tiempo real y emite los eventos
/// correspondientes al BLoC.
class CambiarContrasenaContent extends StatelessWidget {
  final CambiarContrasenaBloc? bloc;

  const CambiarContrasenaContent(this.bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CambiarContrasenaBloc, CambiarContrasenaState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        return Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono decorativo
              Icon(
                Icons.lock_reset,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.cambiarContrasenaTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.cambiarContrasenaDescripcion,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // Campo: contraseña actual
              DefaultTextField(
                label: AppStrings.cambiarContrasenaActual,
                icon: Icons.lock_outline,
                obscureText: true,
                useThemeColors: true,
                onChanged: (texto) {
                  bloc?.add(
                    PasswordActualChanged(
                      passwordActual: BlocForItem(value: texto),
                    ),
                  );
                },
                validator: (_) => state.passwordActual.error,
              ),
              const SizedBox(height: 16),

              // Campo: contraseña nueva
              DefaultTextField(
                label: AppStrings.cambiarContrasenaNueva,
                icon: Icons.lock,
                obscureText: true,
                useThemeColors: true,
                onChanged: (texto) {
                  bloc?.add(
                    PasswordNuevoChanged(
                      passwordNuevo: BlocForItem(value: texto),
                    ),
                  );
                },
                validator: (_) => state.passwordNuevo.error,
              ),
              const SizedBox(height: 16),

              // Campo: confirmar contraseña nueva
              DefaultTextField(
                label: AppStrings.cambiarContrasenaConfirmar,
                icon: Icons.lock,
                obscureText: true,
                useThemeColors: true,
                onChanged: (texto) {
                  bloc?.add(
                    PasswordConfirmarChanged(
                      passwordConfirmar: BlocForItem(value: texto),
                    ),
                  );
                },
                validator: (_) => state.passwordConfirmar.error,
              ),
              const SizedBox(height: 28),

              // Botón de envío
              PrimaryElevatedButton(
                text: 'Cambiar Contraseña',
                onPressed: () {
                  final formValido =
                      state.formKey?.currentState?.validate() ?? false;
                  if (formValido) {
                    bloc?.add(const CambiarContrasenaSubmitted());
                  } else {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        icon: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        title: const Text(AppStrings.validacionCamposIncompletos),
                        content: const Text(AppStrings.cambiarContrasenaCamposMsg),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(AppStrings.accept),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
