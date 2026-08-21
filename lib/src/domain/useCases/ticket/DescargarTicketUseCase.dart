import 'package:arjipagos/src/domain/repository/TicketRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso que deja listo el ticket de un pago para abrirlo o compartirlo.
///
/// Encapsula la descarga autenticada del PDF y su escritura en la carpeta
/// temporal del dispositivo.
class DescargarTicketUseCase {
  final TicketRepository repository;

  DescargarTicketUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con la ruta absoluta del PDF o [Error] con un mensaje
  /// legible para el usuario.
  Future<Resource<String>> run(String url, String folio) async {
    return await repository.descargarTicket(url, folio);
  }
}
