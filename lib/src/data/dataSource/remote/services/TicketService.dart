import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP que descarga el PDF del ticket de un pago realizado.
///
/// El endpoint (`ticket_url`) está detrás del guard de API, así que la petición
/// va con Bearer token. Se manda `Accept: application/json` en primer lugar a
/// propósito: sin eso, Laravel responde a una sesión inválida con un `302` hacia
/// la página de login en HTML, y el error llegaría disfrazado de éxito. Con esa
/// cabecera devuelve un `401` limpio que sí podemos distinguir.
class TicketService {
  final AuthUseCases authUseCases;

  TicketService(this.authUseCases);

  /// Descarga el ticket y devuelve sus bytes.
  ///
  /// Retorna [Success] con el PDF o [Error] con un mensaje legible.
  Future<Resource<Uint8List>> descargarTicket(String url) async {
    if (url.isEmpty) {
      return Error<Uint8List>(AppStrings.ticketNoDisponible);
    }

    try {
      final AuthResponse? sesion = await authUseCases.getUserSession.run();

      if (sesion == null) {
        AppLogger.warning('Intento de abrir un ticket sin sesión', tag: 'Ticket');
        return Error<Uint8List>(AppStrings.errorNoSession);
      }

      if (sesion.accessToken.isEmpty) {
        AppLogger.warning('Token vacío al abrir el ticket', tag: 'Ticket');
        return Error<Uint8List>(AppStrings.errorNoToken);
      }

      // El backend de desarrollo firma `ticket_url` con `localhost`, que no
      // resuelve desde el emulador ni desde un teléfono físico. En producción
      // la URL ya viene con el host real y esto la deja intacta.
      final String urlFinal = ApiConfig.repararUrlDelBackend(url);

      AppLogger.httpRequest('GET', urlFinal);

      final response = await http.get(
        Uri.parse(urlFinal),
        headers: {
          'Accept': 'application/json, application/pdf',
          'Authorization': 'Bearer ${sesion.accessToken}',
        },
      ).timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, urlFinal);

      if (response.statusCode == 401 || response.statusCode == 403) {
        AppLogger.warning('Ticket rechazado por el servidor', tag: 'Ticket');
        return Error<Uint8List>(AppStrings.ticketSesionExpirada);
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'El servidor no entregó el ticket (${response.statusCode})',
          tag: 'Ticket',
        );
        return Error<Uint8List>(AppStrings.ticketErrorCarga);
      }

      // `http` sigue los redirects por su cuenta, así que un 302 hacia la
      // página de login llegaría aquí como un 200 lleno de HTML. Verificar el
      // tipo de contenido es lo único que distingue el ticket real.
      final String tipo =
          response.headers['content-type']?.toLowerCase() ?? '';
      if (!tipo.contains('pdf')) {
        AppLogger.warning(
          'La respuesta del ticket no es un PDF (content-type: $tipo)',
          tag: 'Ticket',
        );
        return Error<Uint8List>(AppStrings.ticketSesionExpirada);
      }

      if (response.bodyBytes.isEmpty) {
        return Error<Uint8List>(AppStrings.ticketErrorCarga);
      }

      AppLogger.info(
        'Ticket descargado (${response.bodyBytes.length} bytes)',
        tag: 'Ticket',
      );
      return Success(response.bodyBytes);
    } on TimeoutException {
      AppLogger.error('Timeout descargando el ticket', tag: 'Ticket');
      return Error<Uint8List>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión descargando el ticket', tag: 'Ticket');
      return Error<Uint8List>(AppStrings.errorConnection);
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error descargando el ticket: $e', tag: 'Ticket');
      return Error<Uint8List>(mensajeErrorRed(e));
    }
  }
}
