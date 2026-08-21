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
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/ListToString.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP de los banners informativos.
///
/// Consume [Endpoints.banners] con Bearer Token y `user_id` en el body, la
/// misma convención que los estados de cuenta: los banners pueden ser
/// distintos para cada usuario.
class BannerService {
  final AuthUseCases authUseCases;

  BannerService(this.authUseCases);

  /// Obtiene los banners del usuario de la sesión.
  ///
  /// Retorna [Success] con [BannersResponse] o [Error] con un mensaje legible.
  Future<Resource<BannersResponse>> getBanners() async {
    try {
      final AuthResponse? authResponse = await authUseCases.getUserSession.run();

      if (authResponse == null) {
        AppLogger.warning('Intento de pedir banners sin sesión', tag: 'Banners');
        return Error<BannersResponse>(AppStrings.errorNoSession);
      }

      final int userId = authResponse.user.id;
      final String token = authResponse.accessToken;

      if (userId == 0) {
        AppLogger.warning('UserId inválido en sesión', tag: 'Banners');
        return Error<BannersResponse>(AppStrings.errorNoUserId);
      }

      if (token.isEmpty) {
        AppLogger.warning('Token vacío en sesión', tag: 'Banners');
        return Error<BannersResponse>(AppStrings.errorNoToken);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.banners);

      AppLogger.httpRequest('POST', url.toString());

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final Map<String, dynamic> body = {
        'user_id': userId,
      };

      final response = await http
          .post(url, headers: headers, body: json.encode(body))
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      // Un error 500 de Laravel llega como página HTML, no como JSON.
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        AppLogger.error(
          'El servidor devolvió HTML en lugar de JSON (posible error 500)',
          tag: 'Banners',
        );
        return Error<BannersResponse>(AppStrings.errorServidorNoDisponible);
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final BannersResponse bannersResponse = BannersResponse.fromJson(data);
        AppLogger.info(
          'Banners cargados: ${bannersResponse.banners.length}',
          tag: 'Banners',
        );
        return Success(bannersResponse);
      } else {
        final errorMsg = ListToString(data['message'] ?? data['msg']);
        AppLogger.warning('Error obteniendo banners: $errorMsg', tag: 'Banners');
        return Error<BannersResponse>(errorMsg);
      }
    } on TimeoutException {
      AppLogger.error('Timeout obteniendo banners', tag: 'Banners');
      return Error<BannersResponse>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión obteniendo banners', tag: 'Banners');
      return Error<BannersResponse>(AppStrings.errorConnection);
    } catch (e) {
      // Nunca exponer la excepción cruda al usuario: el detalle técnico va al
      // log y a la pantalla solo llega un mensaje legible.
      AppLogger.error('Error obteniendo banners: $e', tag: 'Banners');
      return Error<BannersResponse>(mensajeErrorRed(e));
    }
  }
}
