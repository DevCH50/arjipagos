import 'package:equatable/equatable.dart';

/// Eventos del BLoC del ticket de pago.
abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object?> get props => [];
}

/// Descarga el ticket y lo deja listo en la carpeta temporal.
///
/// Se dispara al entrar a la pantalla y también al reintentar tras un error.
class TicketDescargarEvent extends TicketEvent {
  /// URL absoluta del ticket, tal como la envía el backend en `ticket_url`.
  final String url;

  /// Folio del ticket; da nombre al archivo y título a la pantalla.
  final String folio;

  const TicketDescargarEvent({required this.url, required this.folio});

  @override
  List<Object?> get props => [url, folio];
}
