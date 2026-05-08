import 'package:flutter/foundation.dart';

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

  /// Separador de referencia según plataforma: 'I' en iOS, 'A' en Android.
  static const String _sepIOS = 'I';
  static const String _sepAndroid = 'A';

  /// Genera la referencia de pago uniendo los IDs de EstadoDeCuenta con el
  /// separador de plataforma ('I' en iOS, 'A' en Android).
  ///
  /// Ejemplo iOS un item:      `[3399]`              → `"3399I0"`
  /// Ejemplo Android un item:  `[3399]`              → `"3399A0"`
  /// Ejemplo iOS varios:       `[5358, 5359, 5360]`  → `"5358I5359I5360"`
  /// Ejemplo Android varios:   `[5358, 5359, 5360]`  → `"5358A5359A5360"`
  static String generarReferencia(List<int> ids) {
    final sep = defaultTargetPlatform == TargetPlatform.iOS ? _sepIOS : _sepAndroid;
    if (ids.length == 1) {
      return '${ids.first}${sep}0';
    }
    return ids.join(sep);
  }
}
