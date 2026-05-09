import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/html_utils.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// CONSTANTE DEL CANAL DE NOTIFICACIONES
// Definida a nivel de archivo para que la función top-level pueda accederla.
// IMPORTANTE: el valor debe coincidir con el meta-data en AndroidManifest.xml.
// ============================================================================

/// ID del canal de notificaciones Android registrado en el sistema.
const String _kFcmChannelId = 'arjipagos_notif';

/// Nombre del archivo de sonido personalizado (sin extensión) en res/raw/.
/// El archivo existe en android/app/src/main/res/raw/notif_sound.wav
/// y en ios/Runner/notif_sound.wav incluido en el bundle.
const String _kSoundName = 'notif_sound';

// ============================================================================
// HANDLER DE MENSAJES EN BACKGROUND (función top-level obligatoria)
// ============================================================================

/// Maneja los mensajes de Firebase recibidos cuando la app está en segundo plano
/// o terminada.
///
/// Debe ser función de nivel superior (top-level) con [@pragma('vm:entry-point')]
/// para que Firebase Messaging pueda registrarla en un isolate separado.
/// Se registra en main() ANTES de runApp() con
/// [FirebaseMessaging.onBackgroundMessage].
///
/// **Android:** muestra notificación local cuando el sistema no la genera
/// automáticamente:
///  - Mensaje data-only (sin campo `notification`): el sistema no muestra nada.
///  - Mensaje `notification` con título y cuerpo vacíos: el sistema mostraría
///    un globo en blanco; usamos los campos `data` como fallback.
/// **iOS:** APNs gestiona la notificación directamente; no se requiere acción.
@pragma('vm:entry-point')
Future<void> handleFcmBackgroundMessage(RemoteMessage message) async {
  // Requerido para usar plugins en el isolate de background.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase debe inicializarse explícitamente en el isolate de background.
  await Firebase.initializeApp();

  // Log completo del payload para facilitar diagnóstico del backend.
  AppLogger.info(
    'FCM background — notification.title: "${message.notification?.title}" | '
    'notification.body: "${message.notification?.body}"',
    tag: 'FCM',
  );
  AppLogger.info(
    'FCM background — data: ${message.data}',
    tag: 'FCM',
  );

  // En iOS el sistema APNs se encarga de mostrar la notificación.
  if (!Platform.isAndroid) {
    return;
  }

  // Los campos `data` tienen PRIORIDAD sobre `notification`.
  // El backend puede enviar un título genérico (ej: nombre de la app) en
  // notification.title y el contenido real en data.title / data.message.
  final dataTitle = message.data['title']?.toString() ?? '';
  // El campo `message` puede contener HTML; se elimina para mostrar texto plano.
  final dataBody = stripHtml(
    message.data['message']?.toString() ??
    message.data['body']?.toString() ?? '',
  );

  final systemTitle = message.notification?.title ?? '';
  final systemBody = message.notification?.body ?? '';

  // Si el backend usa el nombre de la app como título genérico, ignorarlo.
  final titulo = (dataTitle.isNotEmpty && dataTitle != 'ArjiPagos')
      ? dataTitle
      : (systemTitle.isNotEmpty && systemTitle != 'ArjiPagos')
          ? systemTitle
          : 'ArjiPagos';
  final cuerpo = dataBody.isNotEmpty ? dataBody : systemBody;

  // Solo mostrar notificación local cuando el mensaje es data-only (sin campo
  // `notification`). Si el mensaje tiene campo `notification`, Android ya lo
  // mostró automáticamente antes de que Dart arrancara — mostrar otra aquí
  // causaría un duplicado visible al usuario.
  final esDataOnly = message.notification == null;
  if (esDataOnly && (titulo.isNotEmpty || cuerpo.isNotEmpty)) {
    await _mostrarNotificacionLocalAndroid(
      id: message.hashCode,
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }
}

/// Muestra una notificación local en Android con alta importancia (heads-up).
///
/// Se invoca desde [handleFcmBackgroundMessage] cuando el sistema no genera
/// una notificación automáticamente o la genera con contenido vacío.
Future<void> _mostrarNotificacionLocalAndroid({
  required int id,
  required String titulo,
  required String cuerpo,
}) async {
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  // v21: initialize() y show() usan parámetros nombrados.
  await plugin.initialize(
    settings: const InitializationSettings(
      // Ícono monocromático requerido por Android para la barra de estado.
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    ),
  );

  await plugin.show(
    id: id,
    title: titulo.isNotEmpty ? titulo : null,
    body: cuerpo.isNotEmpty ? cuerpo : null,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _kFcmChannelId,
        AppStrings.fcmChannelNombre,
        channelDescription: AppStrings.fcmChannelDescripcion,
        importance: Importance.high,
        priority: Priority.high,
        // Ícono monocromático en barra de estado (obligatorio desde Android 5+).
        icon: '@drawable/ic_notification',
        // Sonido personalizado del canal; si no existe el archivo usa el default.
        sound: RawResourceAndroidNotificationSound(_kSoundName),
        playSound: true,
      ),
    ),
  );
}

// ============================================================================
// CLASE PRINCIPAL
// ============================================================================

/// Servicio para gestión de Firebase Cloud Messaging (FCM).
///
/// Responsabilidades:
/// - Obtener el token FCM del dispositivo.
/// - Registrar y eliminar el token en el backend (login / logout).
/// - Configurar permisos, canal de notificaciones Android y handlers de FCM.
class FcmService {
  FcmService();

  // ============================================================================
  // TIPO DE DISPOSITIVO
  // ============================================================================

  /// Determina el tipo de dispositivo para el campo `mobile_type` del backend.
  ///
  /// - Android → `'android'`
  /// - iOS     → `'ios'`
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
      // En iOS, el token APNS se registra de forma asíncrona después del arranque.
      // FCM necesita el token APNS antes de poder generar el token FCM.
      // Se reintenta hasta 5 veces con 2 segundos de espera entre intentos.
      if (Platform.isIOS) {
        String? apnsToken;
        int intentos = 0;
        while (apnsToken == null && intentos < 5) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) {
            AppLogger.warning('APNS token no disponible, reintentando (${intentos + 1}/5)...', tag: 'FCM');
            await Future.delayed(const Duration(seconds: 2));
            intentos++;
          }
        }
        if (apnsToken == null) {
          AppLogger.warning('No se pudo obtener APNS token después de 5 intentos', tag: 'FCM');
          return null;
        }
        AppLogger.info('APNS token obtenido correctamente', tag: 'FCM');
      }

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
              'Accept': 'application/json',
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
              'Accept': 'application/json',
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
  /// Pasos:
  /// 1. Solicita permisos de notificación (obligatorio en iOS, Android 13+).
  /// 2. **Android:** crea el canal de alta importancia `arjipagos_notif`
  ///    (sin canal explícito FCM usa uno genérico con baja importancia y sin banner).
  /// 3. **iOS:** configura las opciones de presentación en primer plano.
  ///
  /// El handler de mensajes en background se registra en main() antes de runApp()
  /// con [FirebaseMessaging.onBackgroundMessage].
  Future<void> configurarHandlers() async {
    try {
      // 1. Solicitar permisos al usuario.
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

      // 2. Crear canal de notificaciones Android (requerido para Android 8.0+).
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _kFcmChannelId,
          AppStrings.fcmChannelNombre,
          description: AppStrings.fcmChannelDescripcion,
          importance: Importance.high,
          // Sonido personalizado del canal. Archivo: res/raw/notif_sound.wav
          // NOTA: Android no permite cambiar el sonido de un canal ya creado.
          // Si el canal ya existe en el dispositivo, desinstalar y reinstalar la
          // app para que el nuevo sonido tenga efecto.
          sound: RawResourceAndroidNotificationSound(_kSoundName),
          playSound: true,
        );

        await FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        AppLogger.info('Canal de notificaciones Android creado: $_kFcmChannelId', tag: 'FCM');
      }

      // 3. Configurar presentación en primer plano para iOS.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLogger.info('Handlers de FCM configurados correctamente', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Error al configurar handlers de FCM: $e', tag: 'FCM');
    }
  }
}
