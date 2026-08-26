import 'package:equatable/equatable.dart';

/// Eventos del BLoC de facturas.
abstract class FacturaEvent extends Equatable {
  const FacturaEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial de facturas al abrir la página.
class FacturaInicialEvent extends FacturaEvent {
  const FacturaInicialEvent();
}

/// Refresca la lista de facturas (pull-to-refresh).
class FacturaRefreshEvent extends FacturaEvent {
  const FacturaRefreshEvent();
}

/// Devuelve el BLoC a su estado inicial al cerrar sesión.
///
/// Este BLoC vive en la raíz de la app y sobrevive al cierre de sesión, así que
/// sin esto las facturas del usuario anterior siguen en memoria.
class FacturaLimpiarSesionEvent extends FacturaEvent {
  const FacturaLimpiarSesionEvent();
}
