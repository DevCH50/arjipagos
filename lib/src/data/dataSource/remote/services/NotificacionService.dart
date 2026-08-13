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
import 'package:arjipagos/src/domain/models/notificacion/NotificacionResponse.dart';
import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para gestión de notificaciones del usuario.
///
/// Consume los endpoints de notificaciones del backend usando
/// Bearer Token obtenido de la sesión activa.
class NotificacionService {
  final AuthUseCases authUseCases;

  NotificacionService(this.authUseCases);

  // ============================================================================
  // MÉTODOS PRIVADOS DE APOYO
  // ============================================================================

  /// Obtiene el token de autenticación y valida la sesión activa.
  ///
  /// Retorna [null] si la sesión no existe o el token está vacío.
  Future<String?> _obtenerToken() async {
    final AuthResponse? authResponse = await authUseCases.getUserSession.run();

    if (authResponse == null) {
      AppLogger.warning('Intento de acceso a notificaciones sin sesión', tag: 'Notificacion');
      return null;
    }

    final String token = authResponse.accessToken;

    if (token.isEmpty) {
      AppLogger.warning('Token vacío en sesión al acceder a notificaciones', tag: 'Notificacion');
      return null;
    }

    return token;
  }

  /// Construye los headers HTTP con autenticación Bearer.
  Map<String, String> _buildHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ============================================================================
  // MÉTODOS PÚBLICOS
  // ============================================================================

  /// Obtiene la lista paginada de notificaciones del usuario autenticado.
  ///
  /// [page] indica el número de página (por defecto 1).
  /// Retorna [Success] con la lista de [Notificacion] o [Error] con mensaje.
  Future<Resource<List<Notificacion>>> getNotificaciones({int page = 1}) async {
    try {
      final String? token = await _obtenerToken();

      if (token == null) {
        return Error<List<Notificacion>>(AppStrings.errorNoSession);
      }

      // Construir URL con query param de paginación
      final Uri url = ApiConfig.buildUri(
        Endpoints.notificaciones,
        {'page': page.toString()},
      );

      AppLogger.httpRequest('GET', url.toString());

      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Verificar respuesta HTML inesperada del servidor
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        AppLogger.error('El servidor devolvió HTML en lugar de JSON', tag: 'Notificacion');
        return Error<List<Notificacion>>(
          'El servidor no está disponible en este momento. Por favor intenta más tarde.',
        );
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final NotificacionResponse notificacionResponse =
            NotificacionResponse.fromJson(data);

        AppLogger.info(
          'Notificaciones cargadas: ${notificacionResponse.data.length} elementos (página $page)',
          tag: 'Notificacion',
        );

        return Success(notificacionResponse.data);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al obtener notificaciones', tag: 'Notificacion');
        return Error<List<Notificacion>>(AppStrings.errorUnauthorized);
      } else {
        final String errorMsg =
            data['msg']?.toString() ?? AppStrings.errorUnexpected;
        AppLogger.warning('Error HTTP ${response.statusCode}: $errorMsg', tag: 'Notificacion');
        return Error<List<Notificacion>>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al obtener notificaciones', tag: 'Notificacion');
      return Error<List<Notificacion>>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al obtener notificaciones', tag: 'Notificacion');
      return Error<List<Notificacion>>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al obtener notificaciones: $e', tag: 'Notificacion');
      return Error<List<Notificacion>>(mensajeErrorRed(e));
    }
  }

  /// Obtiene el conteo de notificaciones no leídas del usuario.
  ///
  /// Retorna [Success] con el número entero de no leídas o [Error].
  Future<Resource<int>> getCountNoLeidas() async {
    try {
      final String? token = await _obtenerToken();

      if (token == null) {
        return Error<int>(AppStrings.errorNoSession);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.notificacionesNoLeidas);

      AppLogger.httpRequest('GET', url.toString());

      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        AppLogger.error('El servidor devolvió HTML en lugar de JSON', tag: 'Notificacion');
        return Error<int>(
          'El servidor no está disponible en este momento. Por favor intenta más tarde.',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // El backend responde con {"no_leidas": N}
        final int count = data['no_leidas'] as int? ??
            data['count'] as int? ??
            0;
        AppLogger.info('Notificaciones no leídas: $count', tag: 'Notificacion');
        return Success(count);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al obtener conteo de no leídas', tag: 'Notificacion');
        return Error<int>(AppStrings.errorUnauthorized);
      } else {
        final String errorMsg = data['msg']?.toString() ?? AppStrings.errorUnexpected;
        AppLogger.warning('Error HTTP ${response.statusCode}: $errorMsg', tag: 'Notificacion');
        return Error<int>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al obtener conteo de no leídas', tag: 'Notificacion');
      return Error<int>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al obtener conteo de no leídas', tag: 'Notificacion');
      return Error<int>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al obtener conteo de no leídas: $e', tag: 'Notificacion');
      return Error<int>(mensajeErrorRed(e));
    }
  }

  /// Marca una notificación específica como leída.
  ///
  /// [id] es el identificador único de la notificación a marcar.
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> marcarLeida(int id) async {
    try {
      final String? token = await _obtenerToken();

      if (token == null) {
        return Error<bool>(AppStrings.errorNoSession);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.notificacionMarcarLeida(id));

      AppLogger.httpRequest('POST', url.toString());

      // Body vacío — solo se necesita el token en los headers
      final response = await http
          .post(url, headers: _buildHeaders(token))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Notificación $id marcada como leída', tag: 'Notificacion');
        return Success(true);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al marcar notificación como leída', tag: 'Notificacion');
        return Error<bool>(AppStrings.errorUnauthorized);
      } else {
        AppLogger.warning('Error HTTP ${response.statusCode} al marcar notificación $id', tag: 'Notificacion');
        return Error<bool>(AppStrings.errorUnexpected);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al marcar notificación $id como leída', tag: 'Notificacion');
      return Error<bool>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al marcar notificación $id como leída', tag: 'Notificacion');
      return Error<bool>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al marcar notificación $id: $e', tag: 'Notificacion');
      return Error<bool>(mensajeErrorRed(e));
    }
  }

  /// Marca todas las notificaciones del usuario como leídas.
  ///
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> marcarTodasLeidas() async {
    try {
      final String? token = await _obtenerToken();

      if (token == null) {
        return Error<bool>(AppStrings.errorNoSession);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.notificacionesMarcarTodas);

      AppLogger.httpRequest('POST', url.toString());

      // Body vacío — solo se necesita el token en los headers
      final response = await http
          .post(url, headers: _buildHeaders(token))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Todas las notificaciones marcadas como leídas', tag: 'Notificacion');
        return Success(true);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al marcar todas como leídas', tag: 'Notificacion');
        return Error<bool>(AppStrings.errorUnauthorized);
      } else {
        AppLogger.warning('Error HTTP ${response.statusCode} al marcar todas como leídas', tag: 'Notificacion');
        return Error<bool>(AppStrings.errorUnexpected);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al marcar todas las notificaciones como leídas', tag: 'Notificacion');
      return Error<bool>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al marcar todas como leídas', tag: 'Notificacion');
      return Error<bool>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al marcar todas como leídas: $e', tag: 'Notificacion');
      return Error<bool>(mensajeErrorRed(e));
    }
  }
}
