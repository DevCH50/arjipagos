import 'dart:io';
import 'dart:typed_data';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda el PDF del ticket en la carpeta temporal del dispositivo.
///
/// Se usa la carpeta temporal a propósito: el ticket siempre puede volver a
/// descargarse del servidor, así que no tiene sentido ocupar almacenamiento
/// permanente. El sistema operativo la limpia cuando necesita espacio.
class TicketArchivoStorage {
  /// Escribe [bytes] en un archivo PDF y devuelve su ruta absoluta.
  ///
  /// [folio] solo da nombre al archivo, para que el usuario lo reconozca al
  /// compartirlo o guardarlo. Si viene vacío se usa un nombre genérico.
  Future<String> guardarTemporal(Uint8List bytes, String folio) async {
    final directorio = await getTemporaryDirectory();
    final nombre = _nombreArchivo(folio);
    final archivo = File('${directorio.path}/$nombre');

    await archivo.writeAsBytes(bytes, flush: true);
    AppLogger.info('Ticket guardado en ${archivo.path}', tag: 'Ticket');

    return archivo.path;
  }

  /// Construye un nombre de archivo seguro a partir del folio.
  String _nombreArchivo(String folio) {
    final limpio = folio.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    if (limpio.isEmpty) {
      return 'ticket.pdf';
    }
    return 'ticket_$limpio.pdf';
  }
}
