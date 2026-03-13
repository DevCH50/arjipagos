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
        title: const Text('Pago exitoso'),
        content: const Text('Tu pago ha sido procesado correctamente.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAceptar();
            },
            child: const Text('Aceptar'),
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
        title: const Text('Error en el pago'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onVolver();
            },
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReintentar();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
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
        title: const Text('Cancelar pago'),
        content: const Text('¿Estás seguro de que deseas cancelar el pago?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar pago'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancelar();
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
