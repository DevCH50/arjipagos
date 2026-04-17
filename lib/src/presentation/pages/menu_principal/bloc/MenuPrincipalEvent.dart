import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Menú Principal.
abstract class MenuPrincipalEvent extends Equatable {
  const MenuPrincipalEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial que carga los datos del usuario y los items del menú.
class MenuPrincipalInitialEvent extends MenuPrincipalEvent {
  const MenuPrincipalInitialEvent();
}

/// Evento cuando el usuario selecciona un item del menú.
class MenuItemSelected extends MenuPrincipalEvent {
  final String itemId;

  const MenuItemSelected({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

/// Evento para registrar el token FCM tras un login exitoso.
/// Recibe el accessToken directamente para evitar condición de carrera
/// con el guardado asíncrono de sesión en storage.
class MenuPrincipalRegistrarFcm extends MenuPrincipalEvent {
  final String accessToken;

  const MenuPrincipalRegistrarFcm({required this.accessToken});

  @override
  List<Object?> get props => [accessToken];
}

/// Evento para cerrar sesión desde el menú principal.
class MenuPrincipalLogout extends MenuPrincipalEvent {
  const MenuPrincipalLogout();
}
