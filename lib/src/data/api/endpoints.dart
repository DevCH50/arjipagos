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
  // PAGOS
  // ============================================================================

  /// URL externa de Adquira México para procesar pagos
  static const String pagoAdquira = 'https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado';
  /// Webhook de retorno después del pago
  static const String pagoUrlRetorno = 'https://arjipagos.moriah.mx/api/v1/pago-realizado/';
}
