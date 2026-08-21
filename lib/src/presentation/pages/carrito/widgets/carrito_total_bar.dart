import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/formato_monto.dart';
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
                color: AppColors.getBoxShadow(isDark),
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
          '${state.cantidadPagos} ${state.cantidadPagos == 1 ? AppStrings.pagoSingular : AppStrings.pagoPlural}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        // Igual que en Pagos Pendientes: el total se encoge antes que partirse.
        // Con la fuente del sistema en grande se rompía a media cifra.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatearMonto(state.totalAPagar),
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
      label: Text(state.isProcesandoPago ? AppStrings.carritoProcesando : AppStrings.carritoPagar),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
