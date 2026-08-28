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
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para obtener las facturas del usuario.
///
/// Consume el endpoint [Endpoints.facturas] con Bearer Token
/// y user_id en el body. El ZIP de cada factura viene en base64.
class FacturaService {
  final AuthUseCases authUseCases;

  FacturaService(this.authUseCases);

  /// Obtiene la lista de facturas del usuario autenticado.
  ///
  /// Retorna [Success] con [FacturaResponse] o [Error] con mensaje.
  Future<Resource<FacturaResponse>> getFacturas() async {
    try {
      // Obtener sesión activa
      final AuthResponse? authResponse = await authUseCases.getUserSession
          .run();

      if (authResponse == null) {
        AppLogger.warning(
          'Intento de obtener facturas sin sesión',
          tag: 'Factura',
        );
        return Error<FacturaResponse>(AppStrings.errorNoSession);
      }

      final int userId = authResponse.user.id;
      final String token = authResponse.accessToken;

      if (userId == 0) {
        AppLogger.warning('UserId inválido en sesión', tag: 'Factura');
        return Error<FacturaResponse>(AppStrings.errorNoUserId);
      }

      if (token.isEmpty) {
        AppLogger.warning('Token vacío en sesión', tag: 'Factura');
        return Error<FacturaResponse>(AppStrings.errorNoToken);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.facturas);

      AppLogger.httpRequest('POST', url.toString());

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final Map<String, dynamic> body = {'user_id': userId};

      final response = await http
          .post(url, headers: headers, body: json.encode(body))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Detectar respuesta HTML inesperada del servidor
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        AppLogger.error(
          'El servidor devolvió HTML (posible error 500)',
          tag: 'Factura',
        );
        return Error<FacturaResponse>(
          'El servidor no está disponible en este momento. Por favor intenta más tarde.',
        );
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final FacturaResponse facturaResponse = FacturaResponse.fromJson(data);
        AppLogger.info(
          'Facturas cargadas: ${facturaResponse.facturas.length} facturas',
          tag: 'Factura',
        );
        return Success(facturaResponse);
      } else if (esRespuestaSinDatos(response.statusCode, data)) {
        // Sin familia o sin facturas: estado vacío, no error.
        AppLogger.info(
          'El usuario no tiene facturas que mostrar',
          tag: 'Factura',
        );
        return Success(FacturaResponse.vacio());
      } else {
        final errorMsg = ListToString(data['msg']);
        AppLogger.warning(
          'Error obteniendo facturas: $errorMsg',
          tag: 'Factura',
        );
        return Error<FacturaResponse>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout obteniendo facturas', tag: 'Factura');
      return Error<FacturaResponse>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión obteniendo facturas', tag: 'Factura');
      return Error<FacturaResponse>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error obteniendo facturas: $e', tag: 'Factura');
      return Error<FacturaResponse>(mensajeErrorRed(e));
    }
  }
}
