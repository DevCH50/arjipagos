import 'dart:convert';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';

/// Código con el que Adquira rechaza una referencia que ya se usó: «Ya se
/// encuentra un pago con esa referencia».
///
/// No es una tarjeta rechazada: delata que esa referencia **probablemente ya
/// se cobró** y que el aviso de vuelta no llegó (se cerró la app, se cayó la
/// red). Adquira no ofrece forma de consultar el cobro, así que esta es la
/// única señal que hay.
const int kCodigoReferenciaUsadaAdquira = 5;

/// Resultado del procesamiento de respuesta de pago.
class PagoResult {
  final bool success;
  final String message;
  final bool processed;

  /// Código de rechazo de Adquira, si el servidor lo manda.
  ///
  /// Viaja en el JSON del rechazo desde el 2026-10-08. `null` si no llega:
  /// el retorno de OpenPay no lo trae, ni un backend anterior a esa fecha.
  final int? codigo;

  const PagoResult({
    required this.success,
    required this.message,
    required this.processed,
    this.codigo,
  });

  /// Si Adquira rechazó porque la referencia ya se había usado.
  ///
  /// En ese caso puede que el dinero ya saliera: no se ofrece «Reintentar».
  bool get referenciaYaCobrada =>
      !success && codigo == kCodigoReferenciaUsadaAdquira;

  /// Resultado no procesado (no se detectó respuesta válida).
  static const notProcessed = PagoResult(
    success: false,
    message: '',
    processed: false,
  );
}

/// Utilidad para procesar las respuestas de pago del WebView.
///
/// Maneja tanto respuestas JSON como detección legacy por texto.
class PagoResponseHandler {
  PagoResponseHandler._();

  /// Procesa una respuesta JSON del WebView.
  ///
  /// Retorna [PagoResult] con el resultado del pago.
  static PagoResult procesarJson(String jsonString) {
    // Por AppLogger, no por debugPrint: debugPrint escribe también en Release,
    // y el botón Run de Xcode usa Release (ver CLAUDE.md).
    AppLogger.debug('Respuesta JSON: $jsonString', tag: 'Pago');

    try {
      final respuesta = json.decode(jsonString) as Map<String, dynamic>;
      final success = respuesta['success'] == true;
      final message = respuesta['message']?.toString() ?? '';

      if (success) {
        AppLogger.info('Pago exitoso: $message', tag: 'Pago');
        return PagoResult(success: true, message: message, processed: true);
      } else {
        AppLogger.warning('Pago fallido: $message', tag: 'Pago');
        final errorMsg = message.isNotEmpty
            ? message
            : AppStrings.pagoNoProcesado;
        return PagoResult(
          success: false,
          message: errorMsg,
          processed: true,
          codigo: _codigoDe(respuesta['codigo']),
        );
      }
    } catch (e) {
      AppLogger.error('Error parseando JSON', tag: 'Pago', error: e);
      // Intentar detección legacy
      return procesarLegacy(jsonString);
    }
  }

  /// Lee el `codigo` tolerando entero o texto; `null` si falta o no es número.
  static int? _codigoDe(Object? valor) => switch (valor) {
    final int n => n,
    final String t => int.tryParse(t.trim()),
    _ => null,
  };

  /// Procesa una respuesta de texto usando detección legacy.
  ///
  /// Busca palabras clave para determinar si el pago fue exitoso o fallido.
  static PagoResult procesarLegacy(String texto) {
    final textoLower = texto.toLowerCase();

    // Palabras clave de éxito
    if (textoLower.contains('success') ||
        textoLower.contains('exitoso') ||
        textoLower.contains('aprobado')) {
      return const PagoResult(
        success: true,
        message: AppStrings.pagoProcesadoCorrectamente,
        processed: true,
      );
    }

    // Palabras clave de error
    if (textoLower.contains('error') ||
        textoLower.contains('fallido') ||
        textoLower.contains('rechazado')) {
      return const PagoResult(
        success: false,
        message: AppStrings.pagoNoProcesado,
        processed: true,
      );
    }

    // No se pudo determinar el resultado
    return PagoResult.notProcessed;
  }
}
