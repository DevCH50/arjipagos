import 'package:flutter/foundation.dart';

/// Logger de la aplicación ArjiPagos.
///
/// Proporciona un sistema de logging centralizado que solo
/// muestra mensajes en modo debug, evitando logs en producción.
class AppLogger {
  AppLogger._();

  static const String _tag = 'ArjiPagos';

  // ============================================================================
  // NIVELES DE LOG
  // ============================================================================

  /// Log de debug - información detallada para desarrollo
  static void debug(String message, {String? tag}) {
    _log('DEBUG', tag ?? _tag, message);
  }

  /// Log de información - eventos importantes
  static void info(String message, {String? tag}) {
    _log('INFO', tag ?? _tag, message);
  }

  /// Log de advertencia - situaciones potencialmente problemáticas
  static void warning(String message, {String? tag}) {
    _log('WARNING', tag ?? _tag, message);
  }

  /// Log de error - errores que no detienen la app
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', tag ?? _tag, message);
    if (error != null) {
      _log('ERROR', tag ?? _tag, 'Exception: $error');
    }
    if (stackTrace != null) {
      _log('ERROR', tag ?? _tag, 'StackTrace: $stackTrace');
    }
  }

  /// Log de red - peticiones HTTP
  static void network(String message, {String? tag}) {
    _log('NETWORK', tag ?? _tag, message);
  }

  /// Log de BLoC - eventos y estados
  static void bloc(String message, {String? tag}) {
    _log('BLOC', tag ?? _tag, message);
  }

  /// Log de navegación
  static void navigation(String message, {String? tag}) {
    _log('NAV', tag ?? _tag, message);
  }

  // ============================================================================
  // HELPERS ESPECÍFICOS
  // ============================================================================

  /// Log para inicio de petición HTTP
  static void httpRequest(String method, String url) {
    network('→ $method $url');
  }

  /// Log para respuesta HTTP
  static void httpResponse(int statusCode, String url) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✓' : '✗';
    network('$emoji [$statusCode] $url');
  }

  /// Log para error HTTP
  static void httpError(String url, Object error) {
    network('✗ ERROR $url: $error');
  }

  /// Log para cambio de estado en BLoC
  static void blocTransition(String blocName, String event, String fromState, String toState) {
    bloc('$blocName: $event');
    bloc('  From: $fromState');
    bloc('  To: $toState');
  }

  /// Log para navegación a nueva pantalla
  static void navigateTo(String routeName) {
    navigation('→ Navegando a: $routeName');
  }

  /// Log para pop de pantalla
  static void navigateBack() {
    navigation('← Volviendo');
  }

  // ============================================================================
  // IMPLEMENTACIÓN INTERNA
  // ============================================================================

  /// Método interno para imprimir logs.
  /// Solo imprime en modo debug.
  static void _log(String level, String tag, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      debugPrint('[$timestamp] [$level] [$tag] $message');
    }
  }
}
