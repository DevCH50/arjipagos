import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP de la política de versión mínima.
///
/// A diferencia del resto de servicios, este **no envía Bearer Token**: la
/// consulta ocurre en el arranque, antes de que exista una sesión, para poder
/// bloquear una versión obsoleta aunque el usuario no haya iniciado sesión.
///
/// Cualquier fallo se devuelve como [Error] y quien lo consume lo traduce a
/// "no hay actualización". Nunca se bloquea al usuario por un problema de red.
class VersionService {
  /// Identificador de plataforma que espera el backend.
  ///
  /// Android e iOS llevan políticas separadas porque sus builds se publican por
  /// separado y una tienda puede ir por delante de la otra.
  String get _plataforma => Platform.isIOS ? 'ios' : 'android';

  /// Consulta la política de versión de esta plataforma.
  ///
  /// Retorna [Success] con [VersionApp] o [Error] con un mensaje legible.
  Future<Resource<VersionApp>> getVersion() async {
    try {
      final Uri url = ApiConfig.buildUri(
        Endpoints.appVersion,
        {'plataforma': _plataforma},
      );

      AppLogger.httpRequest('GET', url.toString());

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Un error 500 de Laravel, o un endpoint que todavía no existe, llegan
      // como página HTML y no como JSON.
      final cuerpo = response.body.trim();
      if (cuerpo.startsWith('<!DOCTYPE') || cuerpo.startsWith('<html')) {
        AppLogger.warning(
          'El endpoint de versión devolvió HTML en lugar de JSON',
          tag: 'Version',
        );
        return Error<VersionApp>(AppStrings.errorServidorNoDisponible);
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'El endpoint de versión respondió ${response.statusCode}',
          tag: 'Version',
        );
        return Error<VersionApp>(AppStrings.errorServidorNoDisponible);
      }

      final data = json.decode(cuerpo);

      if (data is! Map<String, dynamic>) {
        AppLogger.warning(
          'La respuesta de versión no es un objeto JSON',
          tag: 'Version',
        );
        return Error<VersionApp>(AppStrings.errorRespuestaInvalida);
      }

      final VersionApp version = VersionApp.fromJson(data);
      AppLogger.info(
        'Política de versión ($_plataforma): build mínimo '
        '${version.buildMinimo}, mantenimiento ${version.mantenimiento}',
        tag: 'Version',
      );
      return Success(version);
    } on TimeoutException {
      AppLogger.warning('Timeout consultando la versión', tag: 'Version');
      return Error<VersionApp>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.warning('Sin conexión consultando la versión', tag: 'Version');
      return Error<VersionApp>(AppStrings.errorConnection);
    } catch (e) {
      // Nunca exponer la excepción cruda al usuario: el detalle técnico va al
      // log y a la pantalla solo llega un mensaje legible.
      AppLogger.error('Error consultando la versión: $e', tag: 'Version');
      return Error<VersionApp>(mensajeErrorRed(e));
    }
  }
}
