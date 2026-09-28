import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget de carga para la página de pago.
class PagoLoadingWidget extends StatelessWidget {
  const PagoLoadingWidget({super.key, this.mensaje = AppStrings.pagoLoading});

  /// Texto bajo el indicador: la carga de la pasarela, o la consulta del
  /// estado del cobro al cerrarla.
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(mensaje),
          ],
        ),
      ),
    );
  }
}
