import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// HANDLER DE MENSAJES EN BACKGROUND (debe ser función top-level)
// ============================================================================

/// Maneja los mensajes de Firebase recibidos en segundo plano.
///
/// Debe ser una función de nivel superior (top-level) para que
/// Firebase Messaging pueda registrarla como handler de background.
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  AppLogger.info(
    'Mensaje en background recibido — id: ${message.messageId}, '
    'título: ${message.notification?.title}',
    tag: 'FCM',
  );
  // Procesamiento adicional puede agregarse aquí según necesidades futuras
}

// ============================================================================
// CLASE PRINCIPAL
// ============================================================================

/// Servicio para gestión de Firebase Cloud Messaging (FCM).
///
/// Maneja la obtención del token del dispositivo, el registro y la eliminación
/// de dicho token en el backend, y la configuración de handlers para
/// notificaciones push en primer y segundo plano.
class FcmService {
  FcmService();

  // ============================================================================
  // TIPO DE DISPOSITIVO
  // ============================================================================

  /// Determina el tipo de dispositivo para el campo `mobile_type` del backend.
  ///
  /// - Android → `'Android'`
  /// - iPad    → `'iPad'`  (shortestSide ≥ 600 dp)
  /// - iPhone  → `'iPhone'`
  String obtenerTipoDispositivo() {
    return Platform.isAndroid ? 'android' : 'ios';
  }

  // ============================================================================
  // TOKEN FCM
  // ============================================================================

  /// Obtiene el token FCM del dispositivo actual.
  ///
  /// Retorna `null` si ocurre cualquier error durante la obtención.
  Future<String?> obtenerToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        AppLogger.info('Token FCM obtenido correctamente', tag: 'FCM');
      } else {
        AppLogger.warning('Token FCM nulo o vacío', tag: 'FCM');
      }

      return token;
    } catch (e) {
      AppLogger.error('Error al obtener token FCM: $e', tag: 'FCM');
      return null;
    }
  }

  // ============================================================================
  // REGISTRO EN BACKEND (POST — al hacer login)
  // ============================================================================

  /// Registra el token FCM en el backend para asociarlo al usuario autenticado.
  ///
  /// Se llama justo después del login exitoso.
  /// [authToken] es el Bearer token de la sesión activa.
  /// [fcmToken] es el token FCM del dispositivo a registrar.
  /// [mobileType] indica la plataforma ('android' o 'ios').
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> registrarToken({
    required String authToken,
    required String fcmToken,
    required String mobileType,
  }) async {
    try {
      if (authToken.isEmpty) {
        AppLogger.warning('Intento de registrar token FCM sin token de auth', tag: 'FCM');
        return Error<bool>(AppStrings.errorNoToken);
      }

      if (fcmToken.isEmpty) {
        AppLogger.warning('Token FCM vacío, no se puede registrar', tag: 'FCM');
        return Error<bool>('Token FCM inválido');
      }

      final Uri url = ApiConfig.buildUri(Endpoints.dispositivoRegistrar);

      AppLogger.httpRequest('POST', url.toString());

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({
              'token': fcmToken,
              'mobile_type': mobileType,
            }),
          )
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Token FCM registrado en backend correctamente', tag: 'FCM');
        return Success(true);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al registrar token FCM', tag: 'FCM');
        return Error<bool>(AppStrings.errorUnauthorized);
      } else {
        AppLogger.warning(
          'Error HTTP ${response.statusCode} al registrar token FCM',
          tag: 'FCM',
        );
        return Error<bool>(AppStrings.errorUnexpected);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al registrar token FCM', tag: 'FCM');
      return Error<bool>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al registrar token FCM', tag: 'FCM');
      return Error<bool>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al registrar token FCM: $e', tag: 'FCM');
      return Error<bool>(e.toString());
    }
  }

  // ============================================================================
  // ELIMINACIÓN EN BACKEND (DELETE — al hacer logout)
  // ============================================================================

  /// Desregistra el token FCM del backend al cerrar sesión o revocar permisos.
  ///
  /// Se llama antes de limpiar la sesión local en el logout.
  /// [authToken] es el Bearer token de la sesión activa (antes de limpiarla).
  /// [fcmToken] es el token FCM del dispositivo a eliminar.
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> eliminarToken({
    required String authToken,
    required String fcmToken,
  }) async {
    try {
      if (authToken.isEmpty || fcmToken.isEmpty) {
        AppLogger.warning('Token de auth o FCM vacío, no se puede eliminar', tag: 'FCM');
        return Error<bool>('Datos inválidos para eliminar token');
      }

      final Uri url = ApiConfig.buildUri(Endpoints.dispositivoEliminar);

      AppLogger.httpRequest('DELETE', url.toString());

      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({'token': fcmToken}),
          )
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info('Token FCM eliminado del backend correctamente', tag: 'FCM');
        return Success(true);
      } else if (response.statusCode == 401) {
        AppLogger.warning('No autorizado al eliminar token FCM', tag: 'FCM');
        return Error<bool>(AppStrings.errorUnauthorized);
      } else {
        AppLogger.warning(
          'Error HTTP ${response.statusCode} al eliminar token FCM',
          tag: 'FCM',
        );
        return Error<bool>(AppStrings.errorUnexpected);
      }
    } on TimeoutException {
      AppLogger.error('Timeout al eliminar token FCM', tag: 'FCM');
      return Error<bool>(AppStrings.errorTimeout);
    } on SocketException {
      AppLogger.error('Sin conexión al eliminar token FCM', tag: 'FCM');
      return Error<bool>(AppStrings.errorConnection);
    } catch (e) {
      AppLogger.error('Error inesperado al eliminar token FCM: $e', tag: 'FCM');
      return Error<bool>(e.toString());
    }
  }

  // ============================================================================
  // CONFIGURACIÓN DE HANDLERS
  // ============================================================================

  /// Configura los permisos y handlers de Firebase Messaging.
  ///
  /// - Solicita permisos de notificación al usuario (obligatorio en iOS, Android 13+).
  /// - Configura las opciones de presentación en primer plano para iOS.
  /// - Registra el handler para mensajes recibidos en background.
  Future<void> configurarHandlers() async {
    try {
      // Solicitar permisos al usuario (requerido en iOS, opcional en Android 13+)
      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info(
        'Permisos de notificación: ${settings.authorizationStatus}',
        tag: 'FCM',
      );

      // Configurar opciones de presentación en primer plano para iOS
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Registrar handler para mensajes en segundo plano
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      AppLogger.info('Handlers de FCM configurados correctamente', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Error al configurar handlers de FCM: $e', tag: 'FCM');
    }
  }
}
