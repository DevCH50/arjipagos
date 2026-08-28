import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/RespuestaSinDatos.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para obtener los estados de cuenta ya pagados.
///
/// Consume el endpoint [Endpoints.estadoCuentaPagados] con Bearer Token y
/// `user_id` en el body, igual que el servicio de pagos pendientes. La
/// respuesta comparte estructura con la de pendientes, por lo que se reutiliza
/// [EstadosDeCuentaResponse]; la diferencia está en los pagos, que llegan con
/// `estadoPago: "Pagado"` y con los datos del ticket.
class EdoCtaPagadosService {
  final AuthUseCases authUseCases;

  EdoCtaPagadosService(this.authUseCases);

  /// Obtiene los estados de cuenta pagados desde el servidor.
  ///
  /// Requiere una sesión activa con token válido.
  /// Envía el user_id en el body como JSON.
  /// Retorna [Success] con [EstadosDeCuentaResponse] o [Error] con mensaje.
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuentaPagados() async {
    try {
      // Obtener userId y token de la sesión
      final AuthResponse? authResponse = await authUseCases.getUserSession
          .run();

      if (authResponse == null) {
        AppLogger.warning(
          'Intento de obtener pagos realizados sin sesión',
          tag: 'EdoCtaPagados',
        );
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoSession);
      }

      final int userId = authResponse.user.id;
      final String token = authResponse.accessToken;

      // Validar datos de sesión
      if (userId == 0) {
        AppLogger.warning('UserId inválido en sesión', tag: 'EdoCtaPagados');
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoUserId);
      }

      if (token.isEmpty) {
        AppLogger.warning('Token vacío en sesión', tag: 'EdoCtaPagados');
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoToken);
      }

      // Construir URL
      final Uri url = ApiConfig.buildUri(Endpoints.estadoCuentaPagados);

      AppLogger.httpRequest('POST', url.toString());

      // Headers con Bearer token
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Body con user_id
      final Map<String, dynamic> body = {'user_id': userId};

      final response = await http
          .post(url, headers: headers, body: json.encode(body))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Verificar si el servidor devolvió HTML en lugar de JSON (error del servidor)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        AppLogger.error(
          'El servidor devolvió HTML en lugar de JSON (posible error 500)',
          tag: 'EdoCtaPagados',
        );
        return Error<EstadosDeCuentaResponse>(
          AppStrings.errorServidorNoDisponible,
        );
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final EstadosDeCuentaResponse edoCtaResponse =
            EstadosDeCuentaResponse.fromJson(data);
        AppLogger.info(
          'Pagos realizados cargados: ${edoCtaResponse.alumnos.length} alumnos',
          tag: 'EdoCtaPagados',
        );
        return Success(edoCtaResponse);
      } else if (esRespuestaSinDatos(response.statusCode, data)) {
        // Sin familia o sin pagos realizados: estado vacío, no error.
        AppLogger.info(
          'El usuario no tiene pagos realizados que mostrar',
          tag: 'EdoCtaPagados',
        );
        return Success(EstadosDeCuentaResponse.vacio());
      } else {
        final errorMsg = ListToString(data['msg']);
        AppLogger.warning(
          'Error obteniendo pagos realizados: $errorMsg',
          tag: 'EdoCtaPagados',
        );
        return Error<EstadosDeCuentaResponse>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error(
        'Timeout obteniendo pagos realizados',
        tag: 'EdoCtaPagados',
      );
      return Error<EstadosDeCuentaResponse>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error(
        'Sin conexión obteniendo pagos realizados',
        tag: 'EdoCtaPagados',
      );
      return Error<EstadosDeCuentaResponse>(AppStrings.errorConnection);
    } catch (e) {
      // Nunca exponer la excepción cruda al usuario: el detalle técnico va al
      // log y a la pantalla solo llega un mensaje legible.
      AppLogger.error(
        'Error obteniendo pagos realizados: $e',
        tag: 'EdoCtaPagados',
      );
      return Error<EstadosDeCuentaResponse>(mensajeErrorRed(e));
    }
  }
}
