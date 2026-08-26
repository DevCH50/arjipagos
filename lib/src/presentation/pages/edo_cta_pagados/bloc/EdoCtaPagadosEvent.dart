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

/// Llegó un push de pago exitoso (`campania: "pago"`).
///
/// Recarga la lista desde el servidor —el pago es de hace segundos y la que hay
/// en memoria todavía no lo tiene— y pide abrir la pantalla.
///
/// [alumnoId] puede ser `null`: el backend lo omite cuando un mismo cobro toca a
/// varios alumnos. Entonces se abre la pantalla sin destacar a nadie.
/// [ticketFolio] también puede faltar, y por el mismo motivo: si el cobro tocó a
/// dos emisores fiscales se emite un ticket por emisor, y mandar uno solo haría
/// pensar que el otro no se cobró.
class EdoCtaPagadosPushRecibidoEvent extends EdoCtaPagadosEvent {
  final int? alumnoId;
  final String? ticketFolio;

  const EdoCtaPagadosPushRecibidoEvent({this.alumnoId, this.ticketFolio});

  @override
  List<Object?> get props => [alumnoId, ticketFolio];
}

/// La app ya navegó a la pantalla: apaga la señal para no repetir el viaje.
class EdoCtaPagadosNavegacionAtendidaEvent extends EdoCtaPagadosEvent {
  const EdoCtaPagadosNavegacionAtendidaEvent();
}

/// La lista ya se desplazó hasta el alumno y lo resaltó: apaga el destacado.
class EdoCtaPagadosDestacadoAtendidoEvent extends EdoCtaPagadosEvent {
  const EdoCtaPagadosDestacadoAtendidoEvent();
}

/// Devuelve el BLoC a su estado inicial al cerrar sesión.
///
/// Este BLoC vive en la raíz de la app y sobrevive al cierre de sesión, así que
/// sin esto los pagos realizados del usuario anterior siguen en memoria.
class EdoCtaPagadosLimpiarSesionEvent extends EdoCtaPagadosEvent {
  const EdoCtaPagadosLimpiarSesionEvent();
}
