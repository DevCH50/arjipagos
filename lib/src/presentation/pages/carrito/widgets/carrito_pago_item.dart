import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Item individual de un pago en el carrito.
///
/// - Si aceptaPagosDiversos = false: Se puede eliminar libremente.
/// - Si aceptaPagosDiversos = true: Solo el pago con ID más alto se puede eliminar.
class CarritoPagoItem extends StatelessWidget {
  final int alumnoId;
  final EstadoDeCuenta pago;
  final bool puedeEliminar;

  const CarritoPagoItem({
    super.key,
    required this.alumnoId,
    required this.pago,
    required this.puedeEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        pago.descripcionAbreviada,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Vence: ${pago.fechaVencimiento}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pago.totalFormatted,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: puedeEliminar
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            tooltip: puedeEliminar
                ? 'Quitar'
                : 'Debe quitar primero los pagos más recientes',
            onPressed: puedeEliminar ? () => _quitarPago(context) : null,
          ),
        ],
      ),
    );
  }

  void _quitarPago(BuildContext context) {
    context.read<CarritoBloc>().add(
      CarritoQuitarPagoEvent(
        alumnoId: alumnoId,
        pagoId: pago.id,
      ),
    );
  }
}
