import 'package:arjipagos/src/domain/useCases/ticket/DescargarTicketUseCase.dart';

/// Agrupador de casos de uso del ticket de pago.
///
/// Se mantiene separado de `EdoCtaPagadosUseCases` porque el ticket no forma
/// parte de la consulta del estado de cuenta: la pantalla de pagos realizados
/// se carga igual aunque nunca se abra un ticket.
class TicketUseCases {
  final DescargarTicketUseCase descargarTicket;

  TicketUseCases({required this.descargarTicket});
}
