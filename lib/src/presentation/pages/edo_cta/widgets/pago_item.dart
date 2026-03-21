import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Item individual de un pago con checkbox para selección.
class PagoItem extends StatelessWidget {
  final Alumno alumno;
  final EstadoDeCuenta pago;
  final List<EstadoDeCuenta> pagosDisponibles;

  const PagoItem({
    super.key,
    required this.alumno,
    required this.pago,
    required this.pagosDisponibles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<EdoCtaListBloc, EdoCtaListState>(
      builder: (context, state) {
        final isSeleccionado = state.isPagoSeleccionado(alumno.alumnoId, pago.id);
        final puedeSeleccionar = _calcularPuedeSeleccionar(state);
        final backgroundColor = _calcularColorFondo(isSeleccionado, isDark);

        return Container(
          color: backgroundColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: _buildCheckbox(context, isSeleccionado, puedeSeleccionar),
            title: _buildTitulo(theme),
            subtitle: _buildSubtitulo(theme),
            trailing: _buildTrailing(theme, isSeleccionado, isDark),
            onTap: () => _onTap(context, puedeSeleccionar, isSeleccionado),
          ),
        );
      },
    );
  }

  /// Calcula si el pago puede ser seleccionado según las reglas.
  bool _calcularPuedeSeleccionar(EdoCtaListState state) {
    if (pago.aceptaPagosDiversos) {
      final idsDisponibles = pagosDisponibles.map((e) => e.id).toList();
      return state.puedeSelecionarPago(alumno.alumnoId, pago.id, idsDisponibles);
    }
    return true; // Sin restricción de orden
  }

  /// Calcula el color de fondo según el estado.
  Color _calcularColorFondo(bool isSeleccionado, bool isDark) {
    if (isSeleccionado) {
      return AppColors.success.withValues(alpha: isDark ? 0.25 : 0.1);
    } else if (pago.estadoPago == EstadoPago.vencido) {
      return AppColors.error.withValues(alpha: isDark ? 0.15 : 0.05);
    }
    return Colors.transparent;
  }

  /// Construye el checkbox de selección.
  Widget _buildCheckbox(
    BuildContext context,
    bool isSeleccionado,
    bool puedeSeleccionar,
  ) {
    return Checkbox(
      value: isSeleccionado,
      onChanged: puedeSeleccionar || isSeleccionado
          ? (value) => _togglePago(context)
          : null,
    );
  }

  /// Construye el título del pago.
  Widget _buildTitulo(ThemeData theme) {
    return Text(
      pago.descripcionAbreviada,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Construye el subtítulo con fecha y estado.
  Widget _buildSubtitulo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
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
        const SizedBox(height: 4),
        EstadoPagoChip(estadoPago: pago.estadoPago),
      ],
    );
  }

  /// Construye el trailing con monto y número de pago.
  Widget _buildTrailing(ThemeData theme, bool isSeleccionado, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          pago.totalFormatted,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSeleccionado
                ? (isDark ? AppColors.successLight : AppColors.success)
                : theme.colorScheme.primary,
          ),
        ),
        Text(
          'Pago #${pago.numPago}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Maneja el tap en el item.
  void _onTap(BuildContext context, bool puedeSeleccionar, bool isSeleccionado) {
    if (puedeSeleccionar || isSeleccionado) {
      _togglePago(context);
    } else {
      _mostrarDialogoInfo(context);
    }
  }

  /// Alterna la selección del pago.
  void _togglePago(BuildContext context) {
    context.read<EdoCtaListBloc>().add(
      EdoCtaTogglePagoEvent(
        alumnoId: alumno.alumnoId,
        pagoId: pago.id,
      ),
    );
  }

  /// Muestra diálogo informativo sobre orden de selección.
  void _mostrarDialogoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.info_outline,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Información'),
        content: const Text(
          'Debes seleccionar primero los pagos anteriores para poder seleccionar este.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
