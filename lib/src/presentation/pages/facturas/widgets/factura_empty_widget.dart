import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget vacío para cuando no hay facturas disponibles.
class FacturaEmptyWidget extends StatelessWidget {
  const FacturaEmptyWidget({super.key});

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
              Icons.receipt_long_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.facturasSinFacturas,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
