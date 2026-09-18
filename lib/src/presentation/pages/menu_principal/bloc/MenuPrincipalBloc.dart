import 'dart:async';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/local/DispositivoStorage.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado del Menú Principal.
///
/// Maneja la carga de datos del usuario, la lista de items del menú
/// y la navegación a las diferentes secciones de la aplicación.
class MenuPrincipalBloc extends Bloc<MenuPrincipalEvent, MenuPrincipalState> {
  final AuthUseCases authUseCases;
  final EdoCtaUseCases edoCtaUseCases;
  final FcmService fcmService;
  final DispositivoStorage dispositivoStorage;

  StreamSubscription<String>? _tokenRefreshSub;

  /// Último token que ya se registró en el backend **en este proceso**.
  ///
  /// Existe para que [_registrarTokenFcm] y [_onFcmTokenRefresh] no manden dos
  /// veces lo mismo: el SDK de Firebase emite `onTokenRefresh` también en la
  /// primera generación del token, así que ambos caminos pueden dispararse casi
  /// a la vez justo después de un login.
  ///
  /// **En memoria y no persistido, a propósito.** Si sobreviviera al cierre de
  /// sesión, otro usuario entrando en el mismo teléfono se saltaría su registro
  /// y se quedaría sin push. Por eso se limpia en [_onLimpiarSesion].
  String? _ultimoTokenRegistrado;

  MenuPrincipalBloc(
    this.authUseCases,
    this.edoCtaUseCases,
    this.fcmService,
    this.dispositivoStorage,
  ) : super(const MenuPrincipalState()) {
    on<MenuPrincipalInitialEvent>(_onInitialEvent);
    on<MenuItemSelected>(_onMenuItemSelected);
    on<MenuPrincipalLimpiarSesion>(_onLimpiarSesion);

    // Escucha renovaciones automáticas de token FCM para mantener el backend
    // sincronizado cuando Firebase rota el token (reinstalación, Play Services, etc.).
    // Se escucha vía FcmService (no FirebaseMessaging.instance) para mantener el
    // BLoC desacoplado de Firebase y testeable con un mock.
    _tokenRefreshSub = fcmService.onTokenRefresh.listen(_onFcmTokenRefresh);
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
  }

  /// Maneja el evento inicial.
  /// Carga los datos del usuario, alumnos y los items del menú.
  Future<void> _onInitialEvent(
    MenuPrincipalInitialEvent event,
    Emitter<MenuPrincipalState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Obtener datos del usuario de la sesión
      final authResponse = await authUseCases.getUserSession.run();

      if (authResponse != null) {
        // Cargar datos básicos del usuario primero
        emit(state.copyWith(
          nombreUsuario: authResponse.user.fullName,
          emailUsuario: authResponse.user.email,
          user: authResponse.user,
          apiVersion: authResponse.apiVersion,
          appVersion: authResponse.appVersion,
          menuItems: MenuPrincipalState.defaultMenuItems,
        ));

        // Registrar token FCM en el backend (sin bloquear la UI)
        _registrarTokenFcm(authResponse.accessToken);

        // Intentar cargar alumnos y familia (puede fallar si no hay conexión)
        try {
          final resource = await edoCtaUseCases.getEstadosDeCuenta.run();

          if (resource is Success<EstadosDeCuentaResponse>) {
            final edoCtaResponse = resource.data;
            emit(state.copyWith(
              isLoading: false,
              familia: edoCtaResponse.familia,
              alumnos: edoCtaResponse.alumnos,
            ));
          } else {
            emit(state.copyWith(isLoading: false));
          }
        } catch (e) {
          // Si falla la carga de alumnos, continuamos sin ellos
          emit(state.copyWith(isLoading: false));
        }
      } else {
        // Sin sesión activa — caso normal al arrancar sin estar logueado.
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        menuItems: MenuPrincipalState.defaultMenuItems,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }

  /// Maneja la selección de un item del menú.
  Future<void> _onMenuItemSelected(
    MenuItemSelected event,
    Emitter<MenuPrincipalState> emit,
  ) async {
    // Emitir el ID seleccionado para que el listener navegue
    emit(state.copyWith(selectedItemId: event.itemId));
    // Resetear el ID para permitir seleccionar el mismo item de nuevo
    emit(state.copyWith(selectedItemId: null));
  }

  /// Registra el token FCM del dispositivo en el backend de forma silenciosa.
  ///
  /// Se llama sin `await` para no bloquear la carga del menú.
  /// Errores son ignorados — el usuario no debe ver fallos de FCM.
  void _registrarTokenFcm(String authToken) {
    Future(() async {
      try {
        final String? fcmToken = await fcmService.obtenerToken();
        if (fcmToken == null) {
          return;
        }
        await _registrarSiHaceFalta(authToken: authToken, fcmToken: fcmToken);
      } catch (e) {
        AppLogger.warning('No se pudo registrar token FCM: $e', tag: 'FCM');
      }
    });
  }

  /// Manda el registro al backend, saltándoselo si ese token ya se registró en
  /// este proceso. Ver [_ultimoTokenRegistrado].
  Future<void> _registrarSiHaceFalta({
    required String authToken,
    required String fcmToken,
  }) async {
    if (_ultimoTokenRegistrado == fcmToken) {
      AppLogger.info(
        'Token FCM ya registrado en esta sesión, no se repite',
        tag: 'FCM',
      );
      return;
    }

    // Se marca ANTES de la petición, no después: los dos caminos corren sin
    // `await` entre ellos y si se marcara al volver, ambos encontrarían el
    // valor vacío y saldrían las dos llamadas igualmente.
    _ultimoTokenRegistrado = fcmToken;

    final resultado = await fcmService.registrarToken(
      authToken: authToken,
      fcmToken: fcmToken,
      mobileType: fcmService.obtenerTipoDispositivo(),
      deviceId: await dispositivoStorage.obtenerDeviceId(),
    );

    // Si falló, se suelta la marca para que el siguiente intento no se la salte.
    if (resultado is! Success<bool>) {
      _ultimoTokenRegistrado = null;
    }
  }

  /// Devuelve el BLoC a su estado inicial al cerrar sesión.
  ///
  /// Se emite un estado nuevo entero, no un `copyWith`: el `copyWith` de
  /// [MenuPrincipalState] nunca vacía un campo (`familia ?? this.familia`), de
  /// modo que arrastraría al usuario anterior. Ver [MenuPrincipalLimpiarSesion].
  void _onLimpiarSesion(
    MenuPrincipalLimpiarSesion event,
    Emitter<MenuPrincipalState> emit,
  ) {
    // Se suelta la marca del token: el siguiente usuario que entre en este
    // teléfono tiene que registrarse, aunque el token del aparato sea el mismo.
    _ultimoTokenRegistrado = null;
    emit(const MenuPrincipalState());
  }

  /// Re-registra el token FCM en el backend cuando Firebase lo rota
  /// automáticamente (reinstalación, actualización de Google Play Services, etc.).
  void _onFcmTokenRefresh(String newToken) {
    Future(() async {
      try {
        final authResponse = await authUseCases.getUserSession.run();
        if (authResponse == null) {
          return;
        }
        await _registrarSiHaceFalta(
          authToken: authResponse.accessToken,
          fcmToken: newToken,
        );
        AppLogger.info('Token FCM renovado y re-registrado en backend', tag: 'FCM');
      } catch (e) {
        AppLogger.warning('No se pudo actualizar token FCM renovado: $e', tag: 'FCM');
      }
    });
  }
}
