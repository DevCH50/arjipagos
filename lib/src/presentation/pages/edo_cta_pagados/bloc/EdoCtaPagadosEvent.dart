import 'package:equatable/equatable.dart';

/// Eventos del BLoC de pagos realizados.
///
/// Solo hay carga y recarga: esta pantalla es de consulta, no permite
/// seleccionar pagos ni enviarlos al carrito.
abstract class EdoCtaPagadosEvent extends Equatable {
  const EdoCtaPagadosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial para cargar los pagos realizados.
class EdoCtaPagadosInitialEvent extends EdoCtaPagadosEvent {
  const EdoCtaPagadosInitialEvent();
}

/// Evento para refrescar la lista de pagos realizados.
class EdoCtaPagadosRefreshEvent extends EdoCtaPagadosEvent {
  const EdoCtaPagadosRefreshEvent();
}
