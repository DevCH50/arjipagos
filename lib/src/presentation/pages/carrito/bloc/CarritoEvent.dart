import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Carrito.
abstract class CarritoEvent extends Equatable {
  const CarritoEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial que carga los items del carrito desde el storage.
class CarritoInitialEvent extends CarritoEvent {
  const CarritoInitialEvent();
}

/// Evento para quitar un pago del carrito.
class CarritoQuitarPagoEvent extends CarritoEvent {
  final int alumnoId;
  final int pagoId;

  const CarritoQuitarPagoEvent({
    required this.alumnoId,
    required this.pagoId,
  });

  @override
  List<Object?> get props => [alumnoId, pagoId];
}

/// Evento para limpiar todo el carrito.
class CarritoLimpiarEvent extends CarritoEvent {
  const CarritoLimpiarEvent();
}

/// Evento para iniciar el proceso de pago.
class CarritoPagarEvent extends CarritoEvent {
  const CarritoPagarEvent();
}

/// Evento cuando el pago fue exitoso.
class CarritoPagoExitosoEvent extends CarritoEvent {
  const CarritoPagoExitosoEvent();
}

/// Evento cuando el pago falló.
class CarritoPagoFallidoEvent extends CarritoEvent {
  final String mensaje;

  const CarritoPagoFallidoEvent(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

/// Evento para cancelar/limpiar el estado de pago pendiente.
class CarritoCancelarPagoEvent extends CarritoEvent {
  const CarritoCancelarPagoEvent();
}

/// Evento para descartar el error que ya se le enseñó al usuario.
///
/// Hace falta porque el diálogo de error lo dispara `carrito_body` mirando
/// `state.errorMessage` en **cada** estado que emite el BLoC, no solo en el que
/// lo trajo. Sin borrarlo, el siguiente cambio del carrito —vaciarlo, quitar un
/// renglón— vuelve a sacar el mismo error, que el usuario ya cerró.
///
/// Visto en el Oppo el 2026-09-24: el cobro por OpenPay falló, el usuario cerró
/// el aviso, vació el carrito, y el aviso reapareció encima del carrito vacío.
class CarritoLimpiarErrorEvent extends CarritoEvent {
  const CarritoLimpiarErrorEvent();
}
