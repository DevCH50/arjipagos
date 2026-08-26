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

/// Llegó un push confirmando un pago **de este emisor fiscal**.
///
/// Lo manda el propio BLoC al reconocer un push de `campania: "pago"` cuyo
/// `emisorfiscal_id` coincide con el suyo. El push de otro emisor no llega
/// aquí: cada lista se queda con lo suyo y ninguna sabe de la otra.
///
/// Lo que provoca es releer los pagos sin pagar, que es justo lo que acaba de
/// cambiar en el servidor: lo recién liquidado ya no debe seguir en la lista.
class EdoCtaListPagoConfirmadoEvent extends EdoCtaListEvent {
  const EdoCtaListPagoConfirmadoEvent();
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

/// Devuelve el BLoC a su estado inicial al cerrar sesión.
///
/// Distinto de [EdoCtaLimpiarSeleccionEvent], que solo desmarca los pagos: esto
/// tira además los alumnos y la respuesta del servidor, que son del usuario que
/// se va. Este BLoC vive en la raíz de la app y sobrevive al cierre de sesión.
class EdoCtaListLimpiarSesionEvent extends EdoCtaListEvent {
  const EdoCtaListLimpiarSesionEvent();
}
