import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cierre de sesión completo: vacía los BLoCs de datos, da de baja el token de
/// FCM y limpia lo local.
///
/// Extraído de `UserDrawer` cuando el cerrojo biométrico necesitó exactamente
/// lo mismo para su "Entrar con mi contraseña". Duplicarlo habría dejado dos
/// copias que se separan a la primera de cambio, y la mitad olvidadiza sería la
/// del FCM: sin dar de baja el token, el teléfono **sigue recibiendo las
/// notificaciones del usuario anterior**.
///
/// **No navega.** Quien llama decide a dónde ir, porque el contexto válido para
/// navegar es distinto en cada caso. La ruta correcta siempre es `'login'` con
/// una variante `restorable*`, nunca montar otro `MyApp` (ver CLAUDE.md).
///
/// El [context] tiene que estar por debajo del `MultiBlocProvider` de `MyApp`,
/// que es donde viven los BLoCs de `blocProviders`. Los dos sitios que llaman
/// aquí lo cumplen: el drawer y `CerrojoBiometrico`, que va en el `builder` del
/// `MaterialApp`.
Future<void> cerrarSesionCompleta(BuildContext context) async {
  final AuthUseCases authUseCases = locator<AuthUseCases>();
  final FcmService fcmService = locator<FcmService>();

  // Los BLoCs se vacían ANTES de cualquier `await`, por dos motivos. Uno, que
  // después del await el `context` puede ya no ser válido. Y dos, que así no
  // queda ni un fotograma con los datos del usuario que se va: la baja del
  // token de FCM es una llamada de red y puede tardar lo suyo.
  _limpiarBlocsDeSesion(context);

  // La sesión se lee ANTES de limpiarla: el token de acceso tiene que seguir
  // siendo válido en el momento del DELETE de FCM, por eso se espera aquí.
  final AuthResponse? authResponse = await authUseCases.getUserSession.run();

  if (authResponse != null) {
    try {
      final String? fcmToken = await fcmService.obtenerToken();
      if (fcmToken != null) {
        await fcmService.eliminarToken(
          authToken: authResponse.accessToken,
          fcmToken: fcmToken,
        );
      }
    } catch (e) {
      // Que falle la baja del token no puede impedir el cierre de sesión: sería
      // dejar al usuario dentro por un problema de red. Se anota y se sigue.
      AppLogger.warning(
        'No se pudo dar de baja el token FCM al cerrar sesión: $e',
        tag: 'Auth',
      );
    }
  }

  await authUseCases.logout.run();
}

/// Devuelve a su estado inicial los BLoCs de datos que viven en la raíz.
///
/// **Hace falta porque los BLoCs de `blocProviders` sobreviven al cierre de
/// sesión**: cuelgan de `MyApp`, que solo se instancia una vez en el `runApp`.
/// Sin esto, lo del usuario anterior sigue en memoria y se queda en pantalla
/// mientras el siguiente login recarga —o para siempre, si esa recarga falla,
/// porque los `copyWith` de estos estados nunca vacían un campo—. Fue el fallo
/// de la familia que no cambiaba al entrar con otro usuario.
///
/// `CarritoBloc` y `NotificacionBloc` no están aquí porque se recargan solos en
/// el `initState` de su página, y su selección se va con el `sharedPref.clear()`
/// del logout. **Si se añade un BLoC de datos a `blocProviders`, hay que
/// vaciarlo aquí también.**
void _limpiarBlocsDeSesion(BuildContext context) {
  context.read<MenuPrincipalBloc>().add(const MenuPrincipalLimpiarSesion());
  context.read<HomeBloc>().add(const HomeLimpiarSesionEvent());
  // Todos los emisores: la sesión es de la app, no de un contrato. Va por el
  // registro y no por `context.read` porque hay una instancia por emisor.
  for (final EdoCtaListBloc bloc in locator<EdoCtaListBlocPorEmisor>().todos) {
    bloc.add(const EdoCtaListLimpiarSesionEvent());
  }
  context.read<EdoCtaPagadosBloc>().add(
        const EdoCtaPagadosLimpiarSesionEvent(),
      );
  context.read<FacturaBloc>().add(const FacturaLimpiarSesionEvent());
}
