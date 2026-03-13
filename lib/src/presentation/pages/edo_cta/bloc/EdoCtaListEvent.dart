import 'package:equatable/equatable.dart';

/// Eventos del BLoC de estados de cuenta.
abstract class EdoCtaListEvent extends Equatable {
  const EdoCtaListEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial para cargar los estados de cuenta.
class EdoCtaListInitialEvent extends EdoCtaListEvent {
  const EdoCtaListInitialEvent();
}

/// Evento para refrescar la lista de estados de cuenta.
class EdoCtaListRefreshEvent extends EdoCtaListEvent {
  const EdoCtaListRefreshEvent();
}

/// Evento para seleccionar/deseleccionar un pago de un alumno.
///
/// [alumnoId] - ID del alumno al que pertenece el pago.
/// [pagoId] - ID del pago (estado de cuenta) a seleccionar/deseleccionar.
class EdoCtaTogglePagoEvent extends EdoCtaListEvent {
  final int alumnoId;
  final int pagoId;

  const EdoCtaTogglePagoEvent({
    required this.alumnoId,
    required this.pagoId,
  });

  @override
  List<Object?> get props => [alumnoId, pagoId];
}

/// Evento para limpiar todos los pagos seleccionados.
class EdoCtaLimpiarSeleccionEvent extends EdoCtaListEvent {
  const EdoCtaLimpiarSeleccionEvent();
}

/// Evento para recargar los pagos seleccionados desde el storage.
/// Se usa cuando se regresa del carrito para sincronizar el estado.
class EdoCtaRecargarSeleccionEvent extends EdoCtaListEvent {
  const EdoCtaRecargarSeleccionEvent();
}
