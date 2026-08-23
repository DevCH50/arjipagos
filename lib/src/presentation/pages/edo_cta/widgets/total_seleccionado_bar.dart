import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/formato_monto.dart';
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
        final totalFormateado = formatearMonto(totalSeleccionado);

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

  Widget _buildInfoTotal(
    ThemeData theme,
    int cantidadPagos,
    String totalFormateado,
    double totalSeleccionado,
  ) {
    // Sustantivo y participio concuerdan en número: con uno solo la frase es
    // "1 pago seleccionado", no "1 pago seleccionados".
    final bool esSingular = cantidadPagos == 1;
    final String sustantivo =
        esSingular ? AppStrings.pagoSingular : AppStrings.pagoPlural;
    final String participio = esSingular
        ? AppStrings.seleccionadoSingular
        : AppStrings.seleccionadoPlural;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$cantidadPagos $sustantivo $participio',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        // El total se encoge antes que partirse. Sin esto, con la fuente del
        // sistema en grande el importe se rompía a media cifra —"$23,136.0" y
        // en el renglón de abajo un "0" suelto—, que es la peor forma posible
        // de enseñar una cantidad de dinero.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            totalFormateado,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: totalSeleccionado > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              // Mismas cifras de ancho fijo que los importes de la lista.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonContinuar(BuildContext context, int cantidadPagos) {
    return ElevatedButton.icon(
      onPressed: cantidadPagos > 0
          ? () => _navegarAlCarrito(context)
          : null,
      icon: const Icon(Icons.shopping_cart),
      label: const Text(AppStrings.edoCtaContinuar),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    );
  }

  /// Navega al carrito y recarga selección al regresar.
  ///
  /// Ruta NO restaurable a propósito: aquí se espera el regreso para recargar
  /// la selección, y `restorablePushNamed` no devuelve un Future. Encaja con
  /// que el WebView de pago tampoco se restaure: si el sistema recicla el
  /// proceso durante el pago, el usuario vuelve a Pagos Pendientes con su
  /// selección intacta —vive en `SeleccionPagosStorage`, no en la pila—.
  Future<void> _navegarAlCarrito(BuildContext context) async {
    await Navigator.pushNamed(context, 'carrito');
    if (context.mounted) {
      context.read<EdoCtaListBloc>().add(
        const EdoCtaRecargarSeleccionEvent(),
      );
    }
  }
}
