/// Duraciones de la aplicación ArjiPagos.
///
/// Centraliza todos los tiempos de espera, animaciones y delays
/// para mantener consistencia en la app.
class AppDurations {
  AppDurations._();

  // ============================================================================
  // TIMEOUTS DE RED
  // ============================================================================

  /// Timeout para peticiones HTTP (30 segundos)
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Espera entre consultas del estado de un cobro de OpenPay que sale
  /// `pendiente` al cerrar el WebView.
  ///
  /// Justo después de pagar, OpenPay puede tardar un momento en marcar el
  /// cargo como completado. El backend sugería esperar 3 y 6 s; se quedó en
  /// 3 y 3 (decisión de Carlos, 2026-09-28): quien cierra sin haber pagado
  /// espera unos 9 s, contando lo que tarda cada consulta (~1 s en el Oppo).
  static const Duration esperaReintentoEstadoOpenpay = Duration(seconds: 3);

  /// Timeout de cada consulta de `GET /openpay/estado` (20 segundos).
  ///
  /// Más corto que [httpTimeout] porque el tutor la espera delante de una
  /// capa, recién cerrado el pago, y una consulta colgada se reintenta. Visto
  /// en el Oppo el 2026-09-29: con la red volviendo, una consulta agotó los
  /// 30 s y la espera pasó de medio minuto. Con 20 s, el peor caso —tres
  /// consultas colgadas y dos esperas— se queda en unos 66 s.
  static const Duration timeoutEstadoOpenpay = Duration(seconds: 20);

  // ============================================================================
  // SPLASH SCREEN
  // ============================================================================

  // ============================================================================
  // ANIMACIONES
  // ============================================================================

  // ============================================================================
  // UI FEEDBACK
  // ============================================================================

  // ============================================================================
  // ACTUALIZACIÓN DE LA APP
  // ============================================================================

  /// Tiempo mínimo entre dos consultas de versión al backend.
  ///
  /// La revisión se dispara al arrancar y cada vez que la app vuelve del
  /// segundo plano; sin este intervalo, alternar entre apps generaría una
  /// petición por cada regreso.
  static const Duration intervaloRevisionVersion = Duration(minutes: 15);
}
