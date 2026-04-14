import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget de error para la página de Facturas.
class FacturaErrorWidget extends StatelessWidget {
  /// Mensaje de error a mostrar.
  final String message;

  /// Callback para reintentar la carga.
  final VoidCallback onRetry;

  const FacturaErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.errorAlCargar,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
