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
