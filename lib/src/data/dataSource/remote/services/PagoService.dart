import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/models/PagoResponse.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para procesar pagos con Adquira México.
///
/// Consume el endpoint [Endpoints.pagoAdquira] para iniciar el proceso de pago.
class PagoService {
  /// Inicia el proceso de pago en Adquira México.
  ///
  /// [pagoRequest] contiene todos los datos necesarios para el pago.
  /// Retorna [Success] con la URL del WebView o [Error] con mensaje.
  Future<Resource<String>> iniciarPago(PagoRequest pagoRequest) async {
    final Uri url = Uri.parse(Endpoints.pagoAdquira);

    AppLogger.httpRequest('POST', url.toString());

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${pagoRequest.token}',
      };

      final response = await http
          .post(url, headers: headers, body: json.encode(pagoRequest.toMap()))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si la respuesta es exitosa, devolver la URL para el WebView
        // La URL puede venir en el body o simplemente usar la URL de pago
        final data = json.decode(response.body);
        final String? urlPago = data['url'] ?? data['redirect_url'];

        if (urlPago != null && urlPago.isNotEmpty) {
          AppLogger.info('URL de pago obtenida: $urlPago', tag: 'Pago');
          return Success(urlPago);
        } else {
          // Si no hay URL en la respuesta, usar la URL base con parámetros
          AppLogger.info('Usando URL base de pago', tag: 'Pago');
          return Success(Endpoints.pagoAdquira);
        }
      } else {
        final data = json.decode(response.body);
        final errorMsg = ListToString(data['msg'] ?? data['message']);
        AppLogger.warning('Error en pago: $errorMsg', tag: 'Pago');
        return Error(errorMsg.isNotEmpty ? errorMsg : AppStrings.errorProcesarPago);
      }
    } on TimeoutException {
      AppLogger.error('Timeout en pago', tag: 'Pago');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión en pago', tag: 'Pago');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error en pago: $e', tag: 'Pago');
      return Error(mensajeErrorRed(e));
    }
  }

  /// Verifica el estado de un pago usando la referencia.
  ///
  /// [referencia] es el ID único del pago a verificar.
  /// [token] es el Bearer token de autenticación.
  /// Retorna [Success] con [PagoResponse] o [Error] con mensaje.
  Future<Resource<PagoResponse>> verificarPago({
    required String referencia,
    required String token,
  }) async {
    final Uri url = Uri.parse('${Endpoints.pagoAdquira}/verificar/$referencia');

    AppLogger.httpRequest('GET', url.toString());

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final pagoResponse = PagoResponse.fromJson(data);
        AppLogger.info('Verificación de pago: ${pagoResponse.message}', tag: 'Pago');
        return Success(pagoResponse);
      } else {
        final errorMsg = ListToString(data['message']);
        AppLogger.warning('Error verificando pago: $errorMsg', tag: 'Pago');
        return Error(errorMsg.isNotEmpty ? errorMsg : AppStrings.errorVerificarPago);
      }
    } on TimeoutException {
      AppLogger.error('Timeout verificando pago', tag: 'Pago');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión verificando pago', tag: 'Pago');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error verificando pago: $e', tag: 'Pago');
      return Error(mensajeErrorRed(e));
    }
  }

  /// Construye la URL completa para el WebView de pago.
  ///
  /// Esta URL se abre directamente en el WebView con los parámetros necesarios.
  String buildPagoUrl(PagoRequest pagoRequest) {
    final params = pagoRequest.toMap();
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '${Endpoints.pagoAdquira}?$queryString';
  }
}
