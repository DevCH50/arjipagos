import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';

/// Apaga el globo rojo que iOS pinta sobre el icono de la app.
///
/// ## Por qué hace falta
///
/// El backend manda `aps.badge` en el payload de APNs, así que iOS pinta el
/// globo en cuanto llega un aviso. **Bajarlo es responsabilidad de la app**, y
/// hasta el 2026-08-27 nadie lo hacía: el globo se quedaba encendido para
/// siempre aunque el usuario ya hubiera leído todo. En Android no se nota
/// porque el sistema no pinta ese contador por su cuenta.
///
/// ## Por qué un canal nativo y no un paquete
///
/// Los paquetes al uso para esto (`flutter_app_badger` y derivados) llevan años
/// sin mantenimiento, y lo que se necesita cabe en unas pocas líneas de Swift.
/// Añadir una dependencia abandonada al proyecto por eso no sale a cuenta.
///
/// El canal está declarado en `ios/Runner/AppDelegate.swift`. En Android y en
/// las pruebas no hay nadie al otro lado, así que las llamadas se descartan
/// antes de salir.
class BadgeIconoApp {
  const BadgeIconoApp._();

  /// Nombre del canal; debe coincidir con el de `AppDelegate.swift`.
  static const MethodChannel _canal =
      MethodChannel('mx.moriah.arjipagos/badge');

  /// Pone a cero el contador del icono.
  ///
  /// Se llama cuando el usuario ya ha visto sus notificaciones: al abrir la
  /// pantalla de Notificaciones y al marcarlas todas como leídas.
  ///
  /// Nunca lanza. Que no se pueda apagar un adorno del icono no es motivo para
  /// romper la pantalla que lo pide.
  static Future<void> limpiar() => fijar(0);

  /// Fija el contador del icono en [cantidad].
  ///
  /// Valores negativos se tratan como cero. En plataformas distintas de iOS no
  /// hace nada: Android no tiene un contador de sistema equivalente y cada capa
  /// de personalización lo resuelve a su manera.
  static Future<void> fijar(int cantidad) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await _canal.invokeMethod<void>('fijar', {
        'cantidad': cantidad < 0 ? 0 : cantidad,
      });
    } on MissingPluginException {
      // No hay canal al otro lado: pasa en las pruebas de widget. No es un
      // fallo que merezca registrarse en cada ejecución.
    } catch (e) {
      AppLogger.warning(
        'No se pudo ajustar el badge del icono: $e',
        tag: 'Badge',
      );
    }
  }
}
