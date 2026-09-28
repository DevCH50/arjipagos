import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/aviso_cierre_cobro.dart';
import 'package:flutter/material.dart';

/// Clase helper para mostrar diálogos relacionados con el pago.
class PagoDialogs {
  /// Muestra diálogo de pago exitoso.
  static Future<void> mostrarExito({
    required BuildContext context,
    required VoidCallback onAceptar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: const Text(AppStrings.pagoExitosoTitle),
        content: const Text(AppStrings.pagoExitosoMsg),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAceptar();
            },
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo de error en el pago.
  static Future<void> mostrarError({
    required BuildContext context,
    required String mensaje,
    required VoidCallback onVolver,
    required VoidCallback onReintentar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.pagoErrorTitle),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onVolver();
            },
            child: const Text(AppStrings.back),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReintentar();
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  /// Muestra el aviso de un cobro de OpenPay cerrado sin retorno.
  ///
  /// Un solo botón, «Aceptar»: a dónde se va después lo decide quien llama,
  /// según [AvisoCierreCobro.vaciarCarrito]. Sin «Reintentar» a propósito: el
  /// tutor vuelve al carrito y pulsa «Pagar», que crea un cobro nuevo con otro
  /// `order_id`, en vez de recargar uno que ya se rechazó.
  static Future<void> mostrarAvisoCierre({
    required BuildContext context,
    required AvisoCierreCobro aviso,
    required VoidCallback onAceptar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ColorScheme colores = Theme.of(ctx).colorScheme;
        final (IconData icono, Color color) = switch (aviso.tipo) {
          TipoAvisoCierre.rechazo => (Icons.error_outline, colores.error),
          TipoAvisoCierre.informativo => (Icons.info_outline, colores.primary),
          TipoAvisoCierre.advertencia => (
            Icons.warning_amber_rounded,
            colores.tertiary,
          ),
        };

        return AlertDialog(
          icon: Icon(icono, color: color, size: 48),
          title: Text(aviso.titulo),
          content: Text(aviso.mensaje),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onAceptar();
              },
              child: const Text(AppStrings.accept),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de confirmación para cancelar el pago.
  static Future<void> confirmarCancelar({
    required BuildContext context,
    required VoidCallback onCancelar,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.pagoCancelarTitle),
        content: const Text(AppStrings.pagoCancelarMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.pagoContinuar),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancelar();
            },
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }
}
