/// Clase que centraliza todos los endpoints de la API.
///
/// Uso:
/// ```dart
/// final url = ApiConfig.buildUri(Endpoints.login);
/// ```
abstract class Endpoints {
  // ============================================================================
  // AUTH
  // ============================================================================

  /// POST - Iniciar sesión
  static const String login = '/api/v1/login';

  /// POST - Registrar usuario
  static const String register = '/api/v1/register';

  // ============================================================================
  // ALUMNOS
  // ============================================================================

  /// GET - Obtener alumnos por usuario
  static String alumnos(String userId) => '/api/v1/alumnos/$userId';

  // ============================================================================
  // ESTADOS DE CUENTA
  // ============================================================================

  /// POST - Obtener estados de cuenta sin pagar
  static const String estadoCuentaSinPagar =
      '/api/v1/alumno/estado-de-cuenta-sin-pagar/';

  // ============================================================================
  // USUARIOS
  // ============================================================================

  /// POST - Cambiar contraseña del usuario autenticado
  static const String cambiarContrasena = '/api/v1/user/change/password/mobile';

  /// POST - Recuperar contraseña (solicitud de restablecimiento)
  static const String recuperarContrasena = '/api/v1/user/recovery/password/mobile';

  // ============================================================================
  // PAGOS
  // ============================================================================

  /// URL externa de Adquira México para procesar pagos
  static const String pagoAdquira =
      'https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado';

  /// Webhook de retorno después del pago
  static const String pagoUrlRetorno =
      'https://arjipagos.moriah.mx/api/v1/pago-realizado/';

  // ============================================================================
  // NOTIFICACIONES
  // ============================================================================

  /// GET - Historial de notificaciones del usuario (paginado)
  static const String notificaciones = '/api/v1/notificaciones';

  /// GET - Conteo de notificaciones no leídas
  static const String notificacionesNoLeidas = '/api/v1/notificaciones/no-leidas';

  /// POST - Marcar una notificación como leída
  static String notificacionMarcarLeida(int id) => '/api/v1/notificaciones/$id/leer';

  /// POST - Marcar todas las notificaciones como leídas
  static const String notificacionesMarcarTodas = '/api/v1/notificaciones/leer-todas';

  // ============================================================================
  // DISPOSITIVO (FCM)
  // ============================================================================

  /// POST - Registrar token FCM del dispositivo al hacer login
  static const String dispositivoRegistrar = '/api/v1/dispositivo/registrar';

  /// DELETE - Desregistrar token FCM del dispositivo al hacer logout
  static const String dispositivoEliminar = '/api/v1/dispositivo/eliminar';
}
