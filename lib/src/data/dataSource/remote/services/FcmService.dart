import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
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

  final TextoPush texto = textoVisibleDelPush(message);

  // Solo mostrar notificación local cuando el mensaje es data-only (sin campo
  // `notification`). Si el mensaje tiene campo `notification`, Android ya lo
  // mostró automáticamente antes de que Dart arrancara — mostrar otra aquí
  // causaría un duplicado visible al usuario.
  final esDataOnly = message.notification == null;
  if (esDataOnly && texto.hayContenido) {
    await _mostrarNotificacionLocalAndroid(
      id: message.hashCode,
      titulo: texto.titulo,
      cuerpo: texto.cuerpo,
    );
  }
}

// ============================================================================
// TEXTO VISIBLE DE UN PUSH
// ============================================================================

/// Título y cuerpo ya resueltos de un push, listos para enseñar.
class TextoPush {
  /// Lo que se pone como título. Nunca vacío: si el push no trae uno propio,
  /// cae en el nombre de la app, porque una notificación sin título se ve rara.
  final String titulo;

  /// Lo que se pone como cuerpo. Puede ser vacío.
  final String cuerpo;

  /// Si el push trae algo que de verdad merezca enseñarse.
  ///
  /// **No es `titulo.isNotEmpty`**: [titulo] siempre tiene algo por el relleno
  /// de arriba. Esto mira el contenido *antes* del relleno, y por eso distingue
  /// un aviso de verdad de un push de puro refresco —los que solo traen
  /// `accion` o `campania` para que la app recargue—, que no debe pintar una
  /// notificación vacía con el nombre de la app.
  final bool hayContenido;

  const TextoPush({
    required this.titulo,
    required this.cuerpo,
    required this.hayContenido,
  });
}

/// Resuelve qué texto enseñarle al usuario a partir del payload del push.
///
/// Las reglas, que valen igual en segundo plano y en primer plano:
///  - Los campos `data` tienen PRIORIDAD sobre `notification`: el backend puede
///    mandar un título genérico en `notification.title` y el contenido real en
///    `data.title` / `data.message`.
///  - `data.message` puede traer HTML, así que se limpia con [stripHtml].
///  - Un título igual al nombre de la app no cuenta como título propio.
TextoPush textoVisibleDelPush(RemoteMessage message) {
  const String generico = 'ArjiPagos';

  final String dataTitle = message.data['title']?.toString() ?? '';
  final String dataBody = stripHtml(
    message.data['message']?.toString() ??
        message.data['body']?.toString() ??
        '',
  );

  final String systemTitle = message.notification?.title ?? '';
  final String systemBody = message.notification?.body ?? '';

  // Título propio: el primero que exista y no sea el nombre de la app.
  final String tituloPropio = (dataTitle.isNotEmpty && dataTitle != generico)
      ? dataTitle
      : (systemTitle.isNotEmpty && systemTitle != generico)
          ? systemTitle
          : '';

  final String cuerpo = dataBody.isNotEmpty ? dataBody : systemBody;

  return TextoPush(
    titulo: tituloPropio.isNotEmpty ? tituloPropio : generico,
    cuerpo: cuerpo,
    hayContenido: tituloPropio.isNotEmpty || cuerpo.isNotEmpty,
  );
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

  // v22: initialize() y show() usan parámetros nombrados.
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

  /// Stream de renovaciones automáticas del token FCM.
  ///
  /// Se expone desde el servicio (en vez de usar `FirebaseMessaging.instance`
  /// directamente en los BLoCs) para mantener la capa de presentación
  /// desacoplada de Firebase y poder mockearlo en tests.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

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
  /// [deviceId] identifica **la instalación**, no el token: es lo que permite al
  /// backend reconocer el mismo teléfono cuando Firebase rota el token y
  /// actualizar su fila en vez de crear otra. Ver `DispositivoStorage`.
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> registrarToken({
    required String authToken,
    required String fcmToken,
    required String mobileType,
    required String deviceId,
  }) async {
    try {
      if (authToken.isEmpty) {
        AppLogger.warning('Intento de registrar token FCM sin token de auth', tag: 'FCM');
        return Error<bool>(AppStrings.errorNoToken);
      }

      if (fcmToken.isEmpty) {
        AppLogger.warning('Token FCM vacío, no se puede registrar', tag: 'FCM');
        return Error<bool>(AppStrings.errorTokenFcmInvalido);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.dispositivoRegistrar);

      // Solo el prefijo: basta para comprobar en el log que el id no cambia
      // entre arranques y sesiones, que es todo su sentido.
      AppLogger.info(
        'Registrando dispositivo ${deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId}…',
        tag: 'FCM',
      );
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
              // El backend lo trata como opcional a propósito, para no romper a
              // las versiones publicadas que aún no lo mandan. Aquí siempre va.
              'device_id': deviceId,
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
      return Error<bool>(mensajeErrorRed(e));
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
        return Error<bool>(AppStrings.errorDatosEliminarToken);
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
      return Error<bool>(mensajeErrorRed(e));
    }
  }

  // ============================================================================
  // CONFIGURACIÓN DE PERMISOS Y CANAL
  // ============================================================================

  /// Prepara los permisos, el canal de Android y la presentación de iOS.
  ///
  /// **No suscribe ningún listener de mensajes, pese al nombre histórico.** Los
  /// push entrantes los escuchan `NotificacionBloc`, `BannerBloc`,
  /// `EdoCtaPagadosBloc` y `EdoCtaListBloc`, cada uno por su cuenta y solo para
  /// refrescar sus datos; el aviso visible con la app abierta lo pone
  /// [mostrarAvisosEnPrimerPlano].
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

  // ============================================================================
  // AVISOS CON LA APP ABIERTA (primer plano)
  // ============================================================================

  /// Enseña el aviso cuando llega un push **con la app en primer plano**.
  ///
  /// ## Por qué hace falta
  ///
  /// Con la app abierta, Android **no pinta nada** por su cuenta: ni siquiera
  /// cuando el push trae bloque `notification`. Y los cuatro BLoC que escuchan
  /// `onMessage` solo refrescan datos y encienden el punto rojo de la campana.
  /// Resultado: el aviso se perdía. Esto lo tapa, reutilizando el mismo canal y
  /// la misma notificación local que ya se usan en segundo plano.
  ///
  /// ## La diferencia con [handleFcmBackgroundMessage] es deliberada
  ///
  /// Allí se exige que el mensaje sea data-only, porque si traía bloque
  /// `notification` el sistema **ya** lo pintó antes de que Dart arrancara y una
  /// segunda notificación sería un duplicado visible. Aquí ese riesgo no existe
  /// —el sistema no pintó nada—, así que la condición desaparece y se muestra
  /// siempre que haya algo que enseñar.
  ///
  /// Los push de puro refresco siguen callados sin necesidad de una lista de
  /// excepciones: no traen texto, y sin texto [TextoPush.hayContenido] es
  /// `false`. Ver esa propiedad.
  ///
  /// **Solo Android.** En iOS el banner en primer plano ya lo saca el sistema,
  /// gracias a `setForegroundNotificationPresentationOptions` en
  /// [configurarHandlers]; duplicarlo aquí pondría dos avisos por push.
  ///
  /// Devuelve la suscripción por si algún día hay que cancelarla. Hoy vive lo
  /// que vive la app.
  StreamSubscription<RemoteMessage>? mostrarAvisosEnPrimerPlano() {
    if (!Platform.isAndroid) {
      return null;
    }

    return FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        final TextoPush texto = textoVisibleDelPush(message);
        if (!texto.hayContenido) {
          return;
        }

        await _mostrarNotificacionLocalAndroid(
          id: message.hashCode,
          titulo: texto.titulo,
          cuerpo: texto.cuerpo,
        );
      } catch (e) {
        // Un fallo al pintar el aviso no puede tumbar la app ni impedir que los
        // BLoC refresquen sus datos con ese mismo push.
        AppLogger.warning(
          'No se pudo mostrar el aviso en primer plano: $e',
          tag: 'FCM',
        );
      }
    });
  }
}
