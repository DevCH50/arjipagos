import 'package:flutter/material.dart';

/// Widget de carga para la página de pago.
class PagoLoadingWidget extends StatelessWidget {
  const PagoLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando página de pago...'),
          ],
        ),
      ),
    );
  }
}
