import 'dart:typed_data';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/local/TicketArchivoStorage.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/TicketService.dart';
import 'package:arjipagos/src/domain/repository/TicketRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio del ticket.
///
/// Encadena las dos mitades del flujo: [TicketService] baja el PDF con el
/// Bearer token y [TicketArchivoStorage] lo escribe en la carpeta temporal.
/// La escritura en disco vive aquí, en la capa de datos, para que el caso de
/// uso solo conozca la ruta final del archivo.
class TicketRepositoryImpl implements TicketRepository {
  final TicketService ticketService;
  final TicketArchivoStorage ticketArchivoStorage;

  TicketRepositoryImpl(this.ticketService, this.ticketArchivoStorage);

  @override
  Future<Resource<String>> descargarTicket(String url, String folio) async {
    try {
      final descarga = await ticketService.descargarTicket(url);

      // El servicio ya devuelve un mensaje legible; se propaga tal cual para
      // no perder el motivo real (sesión expirada, timeout, sin conexión).
      if (descarga is Error<Uint8List>) {
        return Error<String>(descarga.msg);
      }

      if (descarga is! Success<Uint8List>) {
        return Error<String>(AppStrings.ticketErrorCarga);
      }

      final ruta = await ticketArchivoStorage.guardarTemporal(
        descarga.data,
        folio,
      );
      return Success(ruta);
    } catch (e) {
      // El mensaje que llega a la pantalla nunca es la excepción cruda.
      AppLogger.error('Error al preparar el ticket: $e', tag: 'Ticket');
      return Error<String>(mensajeErrorRed(e));
    }
  }
}
