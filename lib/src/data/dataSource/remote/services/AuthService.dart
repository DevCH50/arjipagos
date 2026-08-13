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
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para operaciones de autenticación.
///
/// Maneja las peticiones al API para login y registro de usuarios.
/// Incluye timeout y manejo de errores de conexión.
class AuthService {
  /// Realiza el login del usuario contra el servidor.
  ///
  /// [username] - Nombre de usuario o email.
  /// [password] - Contraseña del usuario.
  /// Retorna [Success] con [AuthResponse] o [Error] con mensaje.
  Future<Resource<AuthResponse>> login(String username, String password) async {
    final Uri url = ApiConfig.buildUri(Endpoints.login);

    AppLogger.httpRequest('POST', url.toString());

    try {
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String bodyParams = json.encode({
        'username': username,
        'password': password,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      });

      final response = await http
          .post(url, headers: headers, body: bodyParams)
          .timeout(AppDurations.httpTimeout);

      final data = json.decode(response.body);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta tiene access_token (login exitoso)
        if (data['access_token'] != null) {
          final AuthResponse authResponse = AuthResponse.fromJson(data);
          AppLogger.info('Login exitoso para usuario: $username', tag: 'Auth');
          return Success(authResponse);
        } else {
          // El servidor devuelve 200 pero sin token (credenciales incorrectas)
          final errorMsg = ListToString(
            data['msg'] ?? data['message'] ?? data['error'] ?? AppStrings.errorInvalidCredentials
          );
          AppLogger.warning('Login fallido (sin token): $errorMsg', tag: 'Auth');
          return Error(errorMsg.isNotEmpty ? errorMsg : AppStrings.errorInvalidCredentials);
        }
      } else {
        // Intentar obtener mensaje de error de diferentes campos posibles
        final errorMsg = ListToString(
          data['msg'] ?? data['message'] ?? data['error'] ?? AppStrings.errorInvalidCredentials
        );
        AppLogger.warning('Login fallido: $errorMsg', tag: 'Auth');
        return Error(errorMsg.isNotEmpty ? errorMsg : AppStrings.errorInvalidCredentials);
      }
    } on TimeoutException {
      AppLogger.error('Timeout en login', tag: 'Auth');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión en login', tag: 'Auth');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error en login: $e', tag: 'Auth');
      return Error(mensajeErrorRed(e));
    }
  }

  /// Cambia la contraseña del usuario autenticado.
  ///
  /// [token] - Token de acceso JWT del usuario.
  /// [userId] - ID del usuario autenticado.
  /// [passwordActual] - Contraseña actual del usuario.
  /// [passwordNuevo] - Nueva contraseña deseada.
  /// Retorna [Success] con mensaje de éxito o [Error] con mensaje.
  Future<Resource<String>> cambiarContrasena({
    required String token,
    required int userId,
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    final Uri url = ApiConfig.buildUri(Endpoints.cambiarContrasena);

    AppLogger.httpRequest('POST', url.toString());

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final String bodyParams = json.encode({
        'user_id': userId,
        'password_actual': passwordActual,
        'password': passwordNuevo,
        'password_confirmation': passwordNuevo,
      });

      final response = await http
          .post(url, headers: headers, body: bodyParams)
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Verificar que la respuesta sea JSON antes de intentar parsear
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json') &&
          response.body.trimLeft().startsWith('<')) {
        AppLogger.error(
          'Respuesta no-JSON (HTTP ${response.statusCode}): servidor devolvió HTML',
          tag: 'Auth',
        );
        return Error(AppStrings.errorServidorHttp(response.statusCode));
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // El servidor puede devolver 200 con status:0 para errores lógicos
        if (data['status'] == 0) {
          final errorMsg = ListToString(
            data['message'] ?? data['msg'] ?? data['error'] ?? 'Error al cambiar contraseña',
          );
          AppLogger.warning('Error lógico del servidor: $errorMsg', tag: 'Auth');
          return Error(errorMsg.isNotEmpty ? errorMsg : 'Error al cambiar contraseña');
        }

        final String message =
            data['message'] ?? data['msg'] ?? 'Contraseña actualizada correctamente';
        AppLogger.info('Contraseña cambiada exitosamente', tag: 'Auth');
        return Success(message);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al cambiar contraseña', tag: 'Auth');
        return Error(AppStrings.errorUnauthorized);
      } else {
        final errorMsg = ListToString(
          data['msg'] ?? data['message'] ?? data['error'] ?? 'Error al cambiar contraseña',
        );
        AppLogger.warning('Error al cambiar contraseña: $errorMsg', tag: 'Auth');
        return Error(errorMsg.isNotEmpty ? errorMsg : 'Error al cambiar contraseña');
      }
    } on TimeoutException {
      AppLogger.error('Timeout al cambiar contraseña', tag: 'Auth');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al cambiar contraseña', tag: 'Auth');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error al cambiar contraseña: $e', tag: 'Auth');
      return Error(mensajeErrorRed(e));
    }
  }

  /// Solicita el restablecimiento de contraseña para el usuario indicado.
  ///
  /// [username] - Nombre de usuario escrito en el diálogo.
  /// [email] - Correo electrónico registrado del usuario.
  /// [deviceName] - Nombre/tipo del dispositivo desde el que se solicita.
  /// Retorna [Success] con mensaje de éxito o [Error] con mensaje.
  Future<Resource<String>> recuperarContrasena({
    required String username,
    required String email,
    required String deviceName,
  }) async {
    final Uri url = ApiConfig.buildUri(Endpoints.recuperarContrasena);

    AppLogger.httpRequest('POST', url.toString());

    try {
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String bodyParams = json.encode({
        'username': username,
        'email': email,
        'device_name': deviceName,
      });

      final response = await http
          .post(url, headers: headers, body: bodyParams)
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json') &&
          response.body.trimLeft().startsWith('<')) {
        AppLogger.error(
          'Respuesta no-JSON (HTTP ${response.statusCode}): servidor devolvió HTML',
          tag: 'Auth',
        );
        return Error(AppStrings.errorServidorHttp(response.statusCode));
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 0) {
          final errorMsg = ListToString(
            data['message'] ?? data['msg'] ?? data['error'] ?? 'Error al recuperar contraseña',
          );
          AppLogger.warning('Error lógico del servidor: $errorMsg', tag: 'Auth');
          return Error(errorMsg.isNotEmpty ? errorMsg : 'Error al recuperar contraseña');
        }
        final String message =
            data['message'] ?? data['msg'] ?? 'Solicitud enviada. Revisa tu correo.';
        AppLogger.info('Recuperación de contraseña solicitada para: $email', tag: 'Auth');
        return Success(message);
      } else {
        final errorMsg = ListToString(
          data['msg'] ?? data['message'] ?? data['error'] ?? 'Error al recuperar contraseña',
        );
        AppLogger.warning('Error al recuperar contraseña: $errorMsg', tag: 'Auth');
        return Error(errorMsg.isNotEmpty ? errorMsg : 'Error al recuperar contraseña');
      }
    } on TimeoutException {
      AppLogger.error('Timeout al recuperar contraseña', tag: 'Auth');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al recuperar contraseña', tag: 'Auth');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error al recuperar contraseña: $e', tag: 'Auth');
      return Error(mensajeErrorRed(e));
    }
  }

  /// Registra un nuevo usuario en el servidor.
  ///
  /// Envía los datos del formulario al endpoint de registro.
  /// Retorna [Success] con mensaje de éxito o [Error] con mensaje de error.
  Future<Resource<String>> register({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String celular,
    required String email,
    required String password,
  }) async {
    final Uri url = ApiConfig.buildUri(Endpoints.register);

    AppLogger.httpRequest('POST', url.toString());

    try {
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String bodyParams = json.encode({
        'nombre': nombre,
        'ap_paterno': apPaterno,
        'ap_materno': apMaterno,
        'celular': celular,
        'email': email,
        'password': password,
      });

      final response = await http
          .post(url, headers: headers, body: bodyParams)
          .timeout(AppDurations.httpTimeout);

      final data = json.decode(response.body);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String message = data['message'] ?? 'Registro exitoso';
        AppLogger.info('Registro exitoso: $email', tag: 'Auth');
        return Success(message);
      } else {
        final errorMsg = ListToString(data['msg'] ?? data['message'] ?? 'Error en el registro');
        AppLogger.warning('Registro fallido: $errorMsg', tag: 'Auth');
        return Error(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout en registro', tag: 'Auth');
      return Error(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión en registro', tag: 'Auth');
      return Error(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error en registro: $e', tag: 'Auth');
      return Error(mensajeErrorRed(e));
    }
  }
}
