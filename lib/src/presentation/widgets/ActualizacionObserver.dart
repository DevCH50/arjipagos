import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionState.dart';
import 'package:arjipagos/src/presentation/utils/AppNavigatorKey.dart';
import 'package:arjipagos/src/presentation/widgets/ActualizacionRequeridaDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Envoltorio que vigila si la app instalada quedó obsoleta.
///
/// Se monta en el `builder` de `MaterialApp`, por encima de todas las páginas,
/// y dispara la comprobación en dos momentos:
///
/// 1. **Tras el primer frame**, cubriendo el arranque en frío. Se hace aquí y
///    no en el splash a propósito: así el bloqueo aplica haya o no sesión, sin
///    tocar la lógica de navegación existente.
/// 2. **Al volver del segundo plano**, que es lo que atrapa las sesiones que
///    quedan abiertas días sin cerrar la app. Esa revisión respeta el intervalo
///    mínimo del BLoC para no consultar en cada cambio de aplicación.
class ActualizacionObserver extends StatefulWidget {
  final Widget child;

  const ActualizacionObserver({super.key, required this.child});

  @override
  State<ActualizacionObserver> createState() => _ActualizacionObserverState();
}

class _ActualizacionObserverState extends State<ActualizacionObserver>
    with WidgetsBindingObserver {
  /// Cuántas veces se vuelve a abrir el diálogo si una navegación se lo lleva.
  ///
  /// Es un tope de seguridad, no un número que se espere alcanzar: en la
  /// práctica basta con una reapertura, la del salto del splash.
  static const int _maxReaperturas = 5;

  /// Cuánto se espera antes de volver a abrir el diálogo que retiró una
  /// navegación.
  ///
  /// No es cosmético: el `removeUntil` del splash sigue vaciando la pila cuando
  /// el futuro del diálogo se completa, y una ruta empujada en ese momento se va
  /// con la misma barrida —sin diálogo y sin aviso—. Esperando a que la
  /// navegación termine, la reapertura se queda.
  static const Duration _esperaTrasNavegacion = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Al primer frame ya hay árbol montado y el navegador existe, que es lo que
    // necesita el diálogo si la comprobación resulta en bloqueo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ActualizacionBloc>().add(
            const ActualizacionVerificarEvent(forzar: true),
          );
    });
  }

  @override
  void dispose() {
    // Sin esto queda un observador de ciclo de vida apuntando a un State muerto.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    super.didChangeAppLifecycleState(estado);

    if (estado != AppLifecycleState.resumed || !mounted) {
      return;
    }

    // Sin forzar: el BLoC decide si ya pasó el intervalo mínimo.
    context.read<ActualizacionBloc>().add(const ActualizacionVerificarEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActualizacionBloc, ActualizacionState>(
      listenWhen: (anterior, actual) => actual.hayDialogoPendiente,
      listener: (context, state) => _mostrarDialogo(state.resultado),
      child: widget.child,
    );
  }

  /// Abre el diálogo sobre la pantalla que esté visible y lo sostiene ahí.
  ///
  /// Usa [appNavigatorKey] porque el contexto de este widget está por encima
  /// del `Navigator` y no serviría para `showDialog`.
  ///
  /// **Por qué hay un bucle:** el splash termina navegando con
  /// `restorablePushNamedAndRemoveUntil(..., (route) => false)`, y ese
  /// predicado retira *todas* las rutas, la del diálogo incluida. Sin esto, un
  /// bloqueo levantado durante el splash se desvanecía solo un segundo después
  /// y el usuario se quedaba dentro con una versión obsoleta.
  ///
  /// Como el diálogo siempre se cierra devolviendo un [CierreActualizacion],
  /// un resultado nulo solo puede significar que se lo llevó una navegación.
  Future<void> _mostrarDialogo(ResultadoActualizacion resultado) async {
    final bloc = context.read<ActualizacionBloc>();
    bloc.add(const ActualizacionDialogoMostradoEvent());

    for (int intento = 0; intento <= _maxReaperturas; intento++) {
      final contextoNavegador = appNavigatorKey.currentContext;

      // Se comprueba el contexto del navegador además del propio State: tras
      // esperar al diálogo, cualquiera de los dos puede haberse desmontado.
      if (contextoNavegador == null || !contextoNavegador.mounted || !mounted) {
        return;
      }

      final cierre = await showDialog<CierreActualizacion>(
        context: contextoNavegador,
        // Nunca por toque fuera: así todo cierre legítimo pasa por un botón o
        // por el atrás, y ambos devuelven un motivo.
        barrierDismissible: false,
        builder: (_) => ActualizacionRequeridaDialog(resultado: resultado),
      );

      if (bloc.isClosed) {
        return;
      }

      if (cierre != null) {
        // Un solo evento en cada caso: mandar el cierre y la comprobación por
        // separado era una carrera que dejaba la pantalla sin aviso.
        bloc.add(
          cierre == CierreActualizacion.reintentar
              ? const ActualizacionReintentarEvent()
              : const ActualizacionDialogoCerradoEvent(),
        );
        return;
      }

      AppLogger.warning(
        'Una navegación retiró el diálogo de actualización; se vuelve a abrir',
        tag: 'Version',
      );

      // Dejar que la navegación que se lo llevó termine de vaciar la pila,
      // o la ruta nueva se iría con ella.
      await Future<void>.delayed(_esperaTrasNavegacion);
    }

    // Agotados los reintentos, no se deja el BLoC creyendo que sigue abierto.
    if (!bloc.isClosed) {
      bloc.add(const ActualizacionDialogoCerradoEvent());
    }
  }
}
