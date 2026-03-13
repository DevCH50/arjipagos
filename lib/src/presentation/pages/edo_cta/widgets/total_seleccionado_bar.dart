import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Barra inferior que muestra el total seleccionado y botón para continuar.
class TotalSeleccionadoBar extends StatelessWidget {
  const TotalSeleccionadoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<EdoCtaListBloc, EdoCtaListState>(
      builder: (context, state) {
        final totalSeleccionado = state.totalSeleccionado;
        final cantidadPagos = state.cantidadPagosSeleccionados;
        final totalFormateado = _formatearMonto(totalSeleccionado);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : Colors.white,
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
                Expanded(
                  child: _buildInfoTotal(
                    theme,
                    cantidadPagos,
                    totalFormateado,
                    totalSeleccionado,
                  ),
                ),
                _buildBotonContinuar(context, cantidadPagos),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formatea el monto como moneda MXN con separadores de miles.
  String _formatearMonto(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final parteEntera = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$parteEntera.${partes[1]}';
  }

  /// Construye la información del total seleccionado.
  Widget _buildInfoTotal(
    ThemeData theme,
    int cantidadPagos,
    String totalFormateado,
    double totalSeleccionado,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$cantidadPagos ${cantidadPagos == 1 ? 'pago' : 'pagos'} seleccionados',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          totalFormateado,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: totalSeleccionado > 0
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Construye el botón para continuar al carrito.
  Widget _buildBotonContinuar(BuildContext context, int cantidadPagos) {
    return ElevatedButton.icon(
      onPressed: cantidadPagos > 0
          ? () => _navegarAlCarrito(context)
          : null,
      icon: const Icon(Icons.shopping_cart),
      label: const Text('Continuar'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    );
  }

  /// Navega al carrito y recarga selección al regresar.
  Future<void> _navegarAlCarrito(BuildContext context) async {
    await Navigator.pushNamed(context, 'carrito');
    if (context.mounted) {
      context.read<EdoCtaListBloc>().add(
        const EdoCtaRecargarSeleccionEvent(),
      );
    }
  }
}
