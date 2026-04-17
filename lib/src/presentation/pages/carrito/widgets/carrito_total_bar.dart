import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Barra inferior con el total y botón de pagar.
class CarritoTotalBar extends StatelessWidget {
  const CarritoTotalBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CarritoBloc, CarritoState>(
      builder: (context, state) {
        if (state.itemsCarrito.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(child: _buildInfoTotal(theme, state)),
                _buildBotonPagar(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTotal(ThemeData theme, CarritoState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${state.cantidadPagos} ${state.cantidadPagos == 1 ? 'pago' : 'pagos'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatearMonto(state.totalAPagar),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonPagar(BuildContext context, CarritoState state) {
    return ElevatedButton.icon(
      onPressed: state.isProcesandoPago
          ? null
          : () => context.read<CarritoBloc>().add(const CarritoPagarEvent()),
      icon: state.isProcesandoPago
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.payment),
      label: Text(state.isProcesandoPago ? 'Procesando...' : 'Pagar'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  String _formatearMonto(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final parteEntera = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$parteEntera.${partes[1]}';
  }
}
