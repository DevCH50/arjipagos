import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio del ticket de un pago realizado.
///
/// Se mantiene aparte del repositorio de pagos realizados porque no consulta
/// el estado de cuenta: descarga un archivo binario y lo deja en disco. Así la
/// pantalla de consulta no arrastra la dependencia del almacenamiento local.
abstract class TicketRepository {
  /// Descarga el ticket de [url] y lo guarda en la carpeta temporal.
  ///
  /// [folio] solo da nombre al archivo, para que el usuario lo reconozca al
  /// compartirlo. Retorna la ruta absoluta del PDF ya escrito en disco.
  Future<Resource<String>> descargarTicket(String url, String folio);
}
