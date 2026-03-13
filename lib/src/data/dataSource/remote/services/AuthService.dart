import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
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
      return Error(e.toString());
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
      return Error(e.toString());
    }
  }
}
