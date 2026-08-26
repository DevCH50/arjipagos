import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/biometria_error_mapper.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/presentation/pages/biometria/CerrojoPantalla.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:arjipagos/src/presentation/utils/AppNavigatorKey.dart';
import 'package:arjipagos/src/presentation/utils/CierreDeSesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Envoltorio que echa el cerrojo biométrico sobre toda la aplicación.
///
/// ## Por qué es un overlay y no una ruta
///
/// Se monta en el `builder` de `MaterialApp`, igual que `ActualizacionObserver`,
/// y tapa la app con un [Stack]. **No** empuja una ruta al `Navigator`, y eso es
/// deliberado: este proyecto ya reventó con un *Stack Overflow* por manipular el
/// árbol de navegación (ver "Volver al login: NUNCA montar un segundo `MyApp`"
/// en CLAUDE.md). Como el `builder` queda por encima del `Navigator`, el cerrojo
/// cubre cualquier pantalla sin tocar la pila, sin duplicar `restorationScopeId`
/// y sin estorbar a los `restorablePushNamedAndRemoveUntil` que ya existen.
///
/// Efecto secundario buscado: al quedar por encima, el cerrojo también tapa el
/// diálogo de actualización obligatoria. Es el orden correcto —primero
/// identifícate, luego hablamos de actualizar—.
class CerrojoBiometrico extends StatefulWidget {
  final Widget child;

  const CerrojoBiometrico({super.key, required this.child});

  @override
  State<CerrojoBiometrico> createState() => _CerrojoBiometricoState();
}

class _CerrojoBiometricoState extends State<CerrojoBiometrico>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Al primer frame ya hay árbol montado, que es lo que necesita el cerrojo
    // para pintarse si el arranque en frío resulta en bloqueo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<BiometriaBloc>().add(const BiometriaIniciada());
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

    if (!mounted) {
      return;
    }

    final BiometriaBloc bloc = context.read<BiometriaBloc>();

    switch (estado) {
      // `hidden` llega antes que `paused` en las versiones recientes del
      // engine; `inactive` NO se usa a propósito, porque también se dispara al
      // bajar el centro de control o al aparecer una llamada, y ahí el usuario
      // no ha salido de la app.
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        bloc.add(const BiometriaAppPausada());
      case AppLifecycleState.resumed:
        bloc.add(const BiometriaAppReanudada());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Cierra la sesión y manda al login, para quien no puede o no quiere pasar
  /// la biometría.
  Future<void> _entrarConContrasena() async {
    final NavigatorState? navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await cerrarSesionCompleta(navigator.context);

    // Se navega ANTES de levantar el cerrojo: al revés, quedaría un fotograma
    // con el menú del usuario visible antes de que la pila se vacíe.
    navigator.restorablePushNamedAndRemoveUntil('login', (route) => false);

    if (!mounted) {
      return;
    }
    context.read<BiometriaBloc>().add(const BiometriaSesionAbandonada());
  }

  /// Muestra el aviso pendiente sobre la pantalla visible.
  ///
  /// Usa [appNavigatorKey] porque el contexto de este widget está por encima del
  /// `Navigator` y no sirve para `showDialog`.
  Future<void> _mostrarAviso(ResultadoBiometria resultado) async {
    context.read<BiometriaBloc>().add(const BiometriaAvisoMostrado());

    final String? mensaje = mensajeResultadoBiometria(resultado);
    final BuildContext? contextoNavegador = appNavigatorKey.currentContext;

    if (mensaje == null || contextoNavegador == null) {
      return;
    }

    await showDialog<void>(
      context: contextoNavegador,
      builder: (BuildContext ctx) => AlertDialog(
        icon: Icon(
          resultado == ResultadoBiometria.noDisponible
              ? Icons.info_outline
              : Icons.lock_outline,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: Text(tituloResultadoBiometria(resultado)),
        content: Text(mensaje),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BiometriaBloc, BiometriaState>(
      listenWhen: (BiometriaState anterior, BiometriaState actual) =>
          actual.avisoPendiente != null &&
          anterior.avisoPendiente != actual.avisoPendiente,
      listener: (BuildContext context, BiometriaState state) =>
          _mostrarAviso(state.avisoPendiente!),
      buildWhen: (BiometriaState anterior, BiometriaState actual) =>
          anterior.bloqueado != actual.bloqueado ||
          anterior.autenticando != actual.autenticando ||
          anterior.estado.disponible != actual.estado.disponible,
      builder: (BuildContext context, BiometriaState state) {
        // El `Stack` se devuelve SIEMPRE, con el cerrojo como segundo hijo
        // opcional. Alternar entre `widget.child` a secas y un `Stack` cambiaría
        // la forma del árbol, y Flutter desmontaría y volvería a montar el
        // subárbol entero —el `Navigator` incluido—, perdiendo la pila de
        // navegación cada vez que el cerrojo aparece o se va. Añadir o quitar el
        // SEGUNDO hijo no toca el elemento del primero.
        return Stack(
          children: <Widget>[
            widget.child,
            if (state.bloqueado)
              CerrojoPantalla(
                disponible: state.estado.disponible,
                autenticando: state.autenticando,
                onDesbloquear: () => context
                    .read<BiometriaBloc>()
                    .add(const BiometriaDesbloqueoSolicitado()),
                onUsarContrasena: _entrarConContrasena,
              ),
          ],
        );
      },
    );
  }
}
