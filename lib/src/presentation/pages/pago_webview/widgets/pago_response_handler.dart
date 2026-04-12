import 'dart:convert';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Resultado del procesamiento de respuesta de pago.
class PagoResult {
  final bool success;
  final String message;
  final bool processed;

  const PagoResult({
    required this.success,
    required this.message,
    required this.processed,
  });

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
    debugPrint('Respuesta JSON: $jsonString');

    try {
      final respuesta = json.decode(jsonString) as Map<String, dynamic>;
      final success = respuesta['success'] == true;
      final message = respuesta['message']?.toString() ?? '';

      if (success) {
        debugPrint('Pago exitoso: $message');
        return PagoResult(
          success: true,
          message: message,
          processed: true,
        );
      } else {
        debugPrint('Pago fallido: $message');
        final errorMsg = message.isNotEmpty
            ? message
            : AppStrings.pagoNoProcesado;
        return PagoResult(
          success: false,
          message: errorMsg,
          processed: true,
        );
      }
    } catch (e) {
      debugPrint('Error parseando JSON: $e');
      // Intentar detección legacy
      return procesarLegacy(jsonString);
    }
  }

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
