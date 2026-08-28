import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget que muestra mensaje cuando no hay pagos pendientes.
///
/// Lleva botón de recargar igual que el estado de error: que no haya nada que
/// mostrar no significa que no vaya a haberlo dentro de un momento —un pago que
/// el colegio acaba de dar de alta, una familia recién asignada—, así que el
/// usuario siempre debe tener a mano cómo volver a pedir sus datos.
class EdoCtaEmptyWidget extends StatelessWidget {
  /// Vuelve a pedir los datos al servidor.
  final VoidCallback onRetry;

  const EdoCtaEmptyWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.edoCtaSinPagosPendientes,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.edoCtaSinEstadosCuenta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
