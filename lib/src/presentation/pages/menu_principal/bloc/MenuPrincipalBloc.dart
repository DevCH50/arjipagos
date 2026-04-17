import 'package:arjipagos/src/core/utils/app_logger.dart';
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

  MenuPrincipalBloc(this.authUseCases, this.edoCtaUseCases, this.fcmService)
      : super(const MenuPrincipalState()) {
    on<MenuPrincipalInitialEvent>(_onInitialEvent);
    on<MenuPrincipalRegistrarFcm>(_onRegistrarFcm);
    on<MenuItemSelected>(_onMenuItemSelected);
    on<MenuPrincipalLogout>(_onLogout);
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
        errorMessage: 'Error al cargar datos: $e',
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

  /// Maneja el registro del token FCM tras login exitoso.
  /// Recibe el accessToken directamente para evitar condición de carrera.
  Future<void> _onRegistrarFcm(
    MenuPrincipalRegistrarFcm event,
    Emitter<MenuPrincipalState> emit,
  ) async {
    _registrarTokenFcm(event.accessToken);
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

  /// Maneja el cierre de sesión.
  ///
  /// Primero elimina el token FCM del backend (antes de limpiar la sesión
  /// local para que el Bearer token aún sea válido), luego ejecuta el logout.
  Future<void> _onLogout(
    MenuPrincipalLogout event,
    Emitter<MenuPrincipalState> emit,
  ) async {
    await _eliminarTokenFcm();
    await authUseCases.logout.run();
  }

  /// Elimina el token FCM del backend de forma silenciosa antes del logout.
  ///
  /// Se necesita el auth token antes de que la sesión sea limpiada localmente,
  /// por eso se obtiene aquí y no después de llamar a logout.
  Future<void> _eliminarTokenFcm() async {
    try {
      final authResponse = await authUseCases.getUserSession.run();
      if (authResponse == null) {
        return;
      }

      final String? fcmToken = await fcmService.obtenerToken();
      if (fcmToken == null) {
        return;
      }

      await fcmService.eliminarToken(
        authToken: authResponse.accessToken,
        fcmToken: fcmToken,
      );
    } catch (e) {
      AppLogger.warning('No se pudo eliminar token FCM en logout: $e', tag: 'FCM');
    }
  }
}
