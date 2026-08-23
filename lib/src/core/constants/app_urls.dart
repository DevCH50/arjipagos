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

  // ============================================================================
  // TIENDAS DE APLICACIONES
  // ============================================================================

  /// Ficha de ArjiPagos en Google Play.
  ///
  /// Es solo un **respaldo**: la URL buena la manda el backend en la respuesta
  /// de versión, para poder corregirla sin publicar un release. Esta constante
  /// se usa si ese campo llega vacío.
  static const String tiendaAndroid =
      'https://play.google.com/store/apps/details?id=mx.moriah.arjipagos';

  /// Ficha de ArjiPagos en la App Store.
  ///
  /// Mismo papel de respaldo que [tiendaAndroid]: el backend manda la buena en
  /// `url_tienda`, y esta solo entra si ese campo llegara vacío.
  /// El nombre lleva tilde y va percent-encoded, igual que lo manda el backend:
  /// un carácter no ASCII crudo en la ruta no sobrevive a `Uri.parse`.
  static const String tiendaIos =
      'https://apps.apple.com/mx/app/arj%C3%AD-pagos/id6760574386';

  /// Identificador numérico de ArjiPagos en la App Store.
  ///
  /// Es el `id6760574386` de [tiendaIos] sin el prefijo. Lo exige
  /// `in_app_review` para abrir la ficha en iOS; en Android no se usa, porque
  /// ahí la ficha se resuelve por el nombre del paquete.
  static const String appStoreId = '6760574386';
}
