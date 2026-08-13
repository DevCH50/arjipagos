import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para obtener estados de cuenta sin pagar.
///
/// Consume el endpoint [Endpoints.estadoCuentaSinPagar]
/// con Bearer Token y user_id en el body.
class EdoCtaService {
  final AuthUseCases authUseCases;

  EdoCtaService(this.authUseCases);

  /// Obtiene los estados de cuenta sin pagar desde el servidor.
  ///
  /// Requiere una sesión activa con token válido.
  /// Envía el user_id en el body como JSON.
  /// Retorna [Success] con [EstadosDeCuentaResponse] o [Error] con mensaje.
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuenta() async {
    try {
      // Obtener userId y token de la sesión
      final AuthResponse? authResponse = await authUseCases.getUserSession.run();

      if (authResponse == null) {
        AppLogger.warning('Intento de obtener estados de cuenta sin sesión', tag: 'EdoCta');
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoSession);
      }

      final int userId = authResponse.user.id;
      final String token = authResponse.accessToken;

      // Validar datos de sesión
      if (userId == 0) {
        AppLogger.warning('UserId inválido en sesión', tag: 'EdoCta');
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoUserId);
      }

      if (token.isEmpty) {
        AppLogger.warning('Token vacío en sesión', tag: 'EdoCta');
        return Error<EstadosDeCuentaResponse>(AppStrings.errorNoToken);
      }

      // Construir URL
      final Uri url = ApiConfig.buildUri(Endpoints.estadoCuentaSinPagar);

      AppLogger.httpRequest('POST', url.toString());

      // Headers con Bearer token
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Body con user_id
      final Map<String, dynamic> body = {
        'user_id': userId,
      };

      final response = await http
          .post(url, headers: headers, body: json.encode(body))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Debug: ver respuesta raw
      AppLogger.info('Response body (primeros 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}', tag: 'EdoCta');

      // Verificar si el servidor devolvió HTML en lugar de JSON (error del servidor)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        AppLogger.error('El servidor devolvió HTML en lugar de JSON (posible error 500)', tag: 'EdoCta');
        return Error<EstadosDeCuentaResponse>(
          'El servidor no está disponible en este momento. Por favor intenta más tarde.',
        );
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final EstadosDeCuentaResponse edoCtaResponse =
            EstadosDeCuentaResponse.fromJson(data);
        AppLogger.info(
          'Estados de cuenta cargados: ${edoCtaResponse.alumnos.length} alumnos',
          tag: 'EdoCta',
        );
        return Success(edoCtaResponse);
      } else {
        final errorMsg = ListToString(data['msg']);
        AppLogger.warning('Error obteniendo estados de cuenta: $errorMsg', tag: 'EdoCta');
        return Error<EstadosDeCuentaResponse>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout obteniendo estados de cuenta', tag: 'EdoCta');
      return Error<EstadosDeCuentaResponse>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión obteniendo estados de cuenta', tag: 'EdoCta');
      return Error<EstadosDeCuentaResponse>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error obteniendo estados de cuenta: $e', tag: 'EdoCta');
      return Error<EstadosDeCuentaResponse>(mensajeErrorRed(e));
    }
  }
}
