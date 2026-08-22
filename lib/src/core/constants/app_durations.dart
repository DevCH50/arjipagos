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

  /// Timeout para conexión inicial (10 segundos)
  static const Duration connectionTimeout = Duration(seconds: 10);

  // ============================================================================
  // SPLASH SCREEN
  // ============================================================================

  /// Tiempo mínimo de splash
  static const Duration splashMinDuration = Duration(milliseconds: 2000);

  /// Intervalo de actualización de progreso
  static const Duration splashProgressInterval = Duration(milliseconds: 100);

  /// Pausa después de completar progreso
  static const Duration splashCompletePause = Duration(milliseconds: 300);

  /// Delay antes de verificar sesión
  static const Duration splashSessionCheckDelay = Duration(milliseconds: 500);

  /// Delay del listener de navegación
  static const Duration splashNavigationDelay = Duration(milliseconds: 200);

  // ============================================================================
  // ANIMACIONES
  // ============================================================================

  /// Duración de animaciones cortas
  static const Duration animationFast = Duration(milliseconds: 200);

  /// Duración de animaciones normales
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Duración de animaciones lentas
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // UI FEEDBACK
  // ============================================================================

  /// Delay para feedback visual en refresh
  static const Duration refreshFeedback = Duration(milliseconds: 500);

  /// Duración de snackbars
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Duración de toasts
  static const Duration toastDuration = Duration(seconds: 2);

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
