import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Panel de respaldo cuando el PDF está en el dispositivo pero no se puede
/// pintar en el visor de la app.
///
/// El camino normal es ver el ticket dentro (`TicketVisorWidget`). Si el motor
/// nativo no logra abrir el documento, el comprobante ya está descargado y no
/// tiene sentido dejar al usuario con una pantalla vacía: se le confirma que el
/// archivo está listo y se le explica por qué se ve así. Las acciones
/// —compartir o abrir con otra app— las ofrece `TicketAccionesBar` justo
/// debajo, para no duplicar botones.
class TicketListoWidget extends StatelessWidget {
  const TicketListoWidget({
    super.key,
    required this.folio,
    required this.explicacion,
  });

  /// Folio del ticket; se muestra bajo el título cuando el backend lo envía.
  final String folio;

  /// Motivo por el que el ticket no se está mostrando en el visor.
  final String explicacion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              // El color del tema cubre claro y oscuro sin tocar nada más.
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.ticketListo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (folio.isNotEmpty) const SizedBox(height: 4),
            if (folio.isNotEmpty)
              Text(
                '${AppStrings.edoCtaPagadosFolio} $folio',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              explicacion,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
