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
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP para operaciones relacionadas con alumnos.
///
/// Maneja las peticiones al API para obtener la lista de alumnos
/// asociados a la familia del usuario autenticado.
/// Incluye timeout y manejo de errores de conexión.
class HomeService {
  final SharedPref sharedPref;
  final AuthUseCases authUseCases;

  HomeService(this.sharedPref, this.authUseCases);

  /// Obtiene la lista de alumnos desde el servidor.
  ///
  /// Requiere una sesión activa con token válido.
  /// Retorna [Success] con [AlumnoResponse] o [Error] con mensaje.
  Future<Resource<AlumnoResponse>> getAlumnos() async {
    try {
      // Obtener userId y token de la sesión
      final AuthResponse? authResponse = await authUseCases.getUserSession
          .run();

      if (authResponse == null) {
        AppLogger.warning('Intento de obtener alumnos sin sesión', tag: 'Home');
        return Error<AlumnoResponse>(AppStrings.errorNoSession);
      }

      final int userId = authResponse.user.id;
      final String token = authResponse.accessToken;

      // Validar datos de sesión
      if (userId == 0) {
        AppLogger.warning('UserId inválido en sesión', tag: 'Home');
        return Error<AlumnoResponse>(AppStrings.errorNoUserId);
      }

      if (token.isEmpty) {
        AppLogger.warning('Token vacío en sesión', tag: 'Home');
        return Error<AlumnoResponse>(AppStrings.errorNoToken);
      }

      // Construir URL con el userId
      final Uri url = ApiConfig.buildUri(Endpoints.alumnos(userId.toString()));

      AppLogger.httpRequest('GET', url.toString());

      // Headers con Bearer token
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(AppDurations.httpTimeout);

      final data = json.decode(response.body);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final AlumnoResponse alumnosResponse = AlumnoResponse.fromJson(data);
        AppLogger.info(
          'Alumnos cargados: ${alumnosResponse.alumnos.length}',
          tag: 'Home',
        );
        return Success(alumnosResponse);
      } else if (esRespuestaSinDatos(response.statusCode, data)) {
        // Sin familia o sin alumnos: estado vacío, no error.
        AppLogger.info('El usuario no tiene alumnos que mostrar', tag: 'Home');
        return Success(AlumnoResponse.vacio());
      } else {
        final errorMsg = ListToString(data['msg']);
        AppLogger.warning('Error obteniendo alumnos: $errorMsg', tag: 'Home');
        return Error<AlumnoResponse>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout obteniendo alumnos', tag: 'Home');
      return Error<AlumnoResponse>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión obteniendo alumnos', tag: 'Home');
      return Error<AlumnoResponse>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error obteniendo alumnos: $e', tag: 'Home');
      return Error<AlumnoResponse>(mensajeErrorRed(e));
    }
  }
}
