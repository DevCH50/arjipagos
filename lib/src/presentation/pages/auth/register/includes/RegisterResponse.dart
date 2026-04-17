import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Widget que maneja las respuestas del registro.
///
/// Muestra indicador de carga durante el proceso y notificaciones
/// de éxito o error según la respuesta del servidor.
class RegisterResponse extends StatelessWidget {
  final RegisterBloc? bloc;

  const RegisterResponse(this.bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        final response = state.response;

        if (response is Error) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: Icon(
                Icons.error_outline,
                color: Theme.of(ctx).colorScheme.error,
                size: 48,
              ),
              title: const Text(AppStrings.error),
              content: Text(response.msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(AppStrings.accept),
                ),
              ],
            ),
          );
        } else if (response is Success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: Icon(
                Icons.check_circle,
                color: Theme.of(ctx).colorScheme.primary,
                size: 48,
              ),
              title: const Text(AppStrings.registerExitosoTitle),
              content: const Text(AppStrings.registerExitosoMsg),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Cerrar diálogo
                    Navigator.pop(context); // Volver al login
                  },
                  child: const Text(AppStrings.registerIrLogin),
                ),
              ],
            ),
          );
        }
      },
      child: BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) {
          final response = state.response;

          if (response is Loading) {
            return Container(
              color: Colors.black54,
              child: const Center(
                child: SpinKitFadingCircle(
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
