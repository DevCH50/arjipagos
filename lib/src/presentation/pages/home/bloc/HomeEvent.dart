import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class GetHomesList extends HomeEvent {
  const GetHomesList();
}

class RefreshHomesList extends HomeEvent {
  const RefreshHomesList();
}

/// Devuelve el BLoC a su estado inicial al cerrar sesión.
///
/// No cierra la sesión (eso es de `cerrarSesionCompleta`): solo descarta los
/// alumnos del usuario que se va, que de otro modo seguirían en memoria porque
/// este BLoC vive en la raíz de la app.
class HomeLimpiarSesionEvent extends HomeEvent {
  const HomeLimpiarSesionEvent();
}
