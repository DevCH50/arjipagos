import 'dart:async';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
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

  StreamSubscription<String>? _tokenRefreshSub;

  MenuPrincipalBloc(this.authUseCases, this.edoCtaUseCases, this.fcmService)
      : super(const MenuPrincipalState()) {
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
        await fcmService.registrarToken(
          authToken: authToken,
          fcmToken: fcmToken,
          mobileType: fcmService.obtenerTipoDispositivo(),
        );
      } catch (e) {
        AppLogger.warning('No se pudo registrar token FCM: $e', tag: 'FCM');
      }
    });
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
        await fcmService.registrarToken(
          authToken: authResponse.accessToken,
          fcmToken: newToken,
          mobileType: fcmService.obtenerTipoDispositivo(),
        );
        AppLogger.info('Token FCM renovado y re-registrado en backend', tag: 'FCM');
      } catch (e) {
        AppLogger.warning('No se pudo actualizar token FCM renovado: $e', tag: 'FCM');
      }
    });
  }
}
