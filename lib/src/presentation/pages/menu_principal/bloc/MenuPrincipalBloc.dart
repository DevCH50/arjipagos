import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
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

  MenuPrincipalBloc(this.authUseCases, this.edoCtaUseCases)
      : super(const MenuPrincipalState()) {
    on<MenuPrincipalInitialEvent>(_onInitialEvent);
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

        // Intentar cargar alumnos y familia (puede fallar si no hay conexión)
        try {
          final resource = await edoCtaUseCases.getEstadosDeCuenta.run();

          if (resource is Success<EstatodosDeCuentaResponse>) {
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
        emit(state.copyWith(
          isLoading: false,
          menuItems: MenuPrincipalState.defaultMenuItems,
          errorMessage: 'No se pudo cargar la información del usuario',
        ));
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

  /// Maneja el cierre de sesión.
  Future<void> _onLogout(
    MenuPrincipalLogout event,
    Emitter<MenuPrincipalState> emit,
  ) async {
    await authUseCases.logout.run();
  }
}
