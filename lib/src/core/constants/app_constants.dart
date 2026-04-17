/// Constantes numéricas de la aplicación ArjiPagos.
///
/// Centraliza valores enteros y de configuración que no son strings
/// para facilitar el mantenimiento y evitar números mágicos en el código.
abstract final class AppConstants {
  // ============================================================================
  // PAGO — REFERENCIA
  // ============================================================================

  /// Longitud máxima permitida para la referencia de pago enviada a Adquira México.
  ///
  /// La referencia se forma concatenando los IDs de EstadoDeCuenta con 'D':
  /// `"5358D5359D5360"`. Si la referencia supera este límite, Adquira rechaza
  /// la transacción. Los IDs deben ir completos — nunca se truncan.
  static const int maxLongitudReferencia = 30;
}
