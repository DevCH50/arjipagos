/// URLs externas de la aplicación accesibles desde la capa de presentación.
///
/// Solo se incluyen aquí las URLs que NO son endpoints de la API REST
/// (es decir, que no pasan por [ApiConfig] ni por repositorios).
abstract class AppUrls {
  // ============================================================================
  // LEGALES / INFORMACIÓN
  // ============================================================================

  /// URL del Aviso de Privacidad (página web externa, HTML completo).
  static const String avisoDePrivacidad =
      'https://arjipagos.moriah.mx/aviso-de-privacidad';
}
