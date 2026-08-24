import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que escucha la respuesta del BLoC y reacciona a los cambios de estado.
///
/// Muestra un indicador de carga durante la petición HTTP.
/// En caso de éxito: Dialog de confirmación y regresa a la pantalla anterior.
/// En caso de error: Dialog con el mensaje del servidor.
class CambiarContrasenaResponse extends StatelessWidget {
  final CambiarContrasenaBloc? bloc;

  const CambiarContrasenaResponse(this.bloc, {super.key});

  /// Muestra un Dialog de éxito y regresa a la pantalla anterior al cerrarlo.
  void _mostrarExito(BuildContext context, String mensaje) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.tertiary,
          size: 48,
        ),
        title: const Text(AppStrings.cambiarContrasenaActualizada),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // cerrar dialog
              // La sesión ya la cerró el BLoC: volver al login removiendo
              // todas las rutas.
              //
              // NO se empuja un `MyApp` nuevo: eso monta un segundo
              // `MaterialApp` dentro del que ya corre, con el mismo
              // `navigatorKey` (un GlobalKey) y el mismo `restorationScopeId`,
              // y Flutter aborta con "Multiple widgets used the same GlobalKey".
              Navigator.restorablePushNamedAndRemoveUntil(
                context,
                'login',
                (route) => false,
              );
            },
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  /// Muestra un Dialog de error con el mensaje del servidor.
  /// La página permanece abierta al cerrarlo.
  void _mostrarError(BuildContext context, String mensaje) {
    final errorColor = Theme.of(context).colorScheme.error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: errorColor,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CambiarContrasenaBloc, CambiarContrasenaState>(
      listenWhen: (previous, current) => previous.response != current.response,
      listener: (context, state) {
        final respuesta = state.response;
        if (respuesta is Success) {
          bloc?.add(const CambiarContrasenaFormReset());
          _mostrarExito(
            context,
            respuesta.data is String
                ? respuesta.data as String
                : AppStrings.cambiarContrasenaExitosoMsg,
          );
        } else if (respuesta is Error) {
          _mostrarError(context, respuesta.msg);
        }
      },
      buildWhen: (previous, current) => previous.response != current.response,
      builder: (context, state) {
        if (state.response is Loading) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
