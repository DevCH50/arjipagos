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

/// Devuelve el BLoC a su estado inicial al cerrar sesión.
///
/// NO cierra la sesión: de eso se encarga `cerrarSesionCompleta`, que es quien
/// da de baja el token de FCM y limpia el almacenamiento. Aquí solo se tira lo
/// que quedó en memoria del usuario que se va.
///
/// Hace falta porque este BLoC vive en `blocProviders`, en la raíz de la app, y
/// sobrevive al cierre de sesión. Sin esto, el `copyWith` —que nunca vacía un
/// campo, `familia ?? this.familia`— dejaba la familia del usuario anterior en
/// pantalla si la recarga del siguiente tardaba o fallaba.
class MenuPrincipalLimpiarSesion extends MenuPrincipalEvent {
  const MenuPrincipalLimpiarSesion();
}
