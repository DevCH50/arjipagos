import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Item individual de un pago en el carrito.
///
/// - Si aceptaPagosDiversos = false: Se puede eliminar libremente.
/// - Si aceptaPagosDiversos = true: Solo el pago con ID más alto se puede eliminar.
///
/// Se maqueta con `Row` + `Expanded` (mismo patrón que `PagoItem`) en lugar de
/// `ListTile`: el `trailing` de un `ListTile` recibe un ancho acotado y el
/// importe junto al botón de quitar lo desbordaban por fracciones de pixel en
/// pantallas angostas. Aquí el bloque derecho toma su ancho intrínseco y es la
/// columna de texto la que cede espacio, por lo que el desbordamiento es
/// imposible en cualquier tamaño de pantalla.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildContenido(theme)),
          const SizedBox(width: 8),
          _buildTrailing(context, theme),
        ],
      ),
    );
  }

  /// Construye la columna con título, fecha de vencimiento y estado.
  Widget _buildContenido(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pago.descripcionAbreviada, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        _buildVencimiento(theme),
        const SizedBox(height: 4),
        EstadoPagoChip(estadoPago: pago.estadoPago),
      ],
    );
  }

  /// Construye la fila de fecha de vencimiento.
  Widget _buildVencimiento(ThemeData theme) {
    final estilo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        // Flexible + ellipsis: en fechas largas o con fuente ampliada por
        // accesibilidad el texto se recorta en vez de desbordar la fila.
        Flexible(
          child: Text(
            '${AppStrings.edoCtaVence} ${pago.fechaVencimiento}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo,
          ),
        ),
      ],
    );
  }

  /// Construye el importe y el botón de quitar del carrito.
  Widget _buildTrailing(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pago.totalFormatted,
          // maxLines + softWrap: false evita que el importe se parta carácter
          // por carácter; al no estar dentro de un ListTile ya dispone de su
          // ancho intrínseco completo.
          maxLines: 1,
          softWrap: false,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        _buildBotonQuitar(context, theme),
      ],
    );
  }

  /// Construye el botón de quitar con su tooltip.
  ///
  /// Tooltip explícito en vez del parámetro `tooltip` del IconButton: el
  /// mensaje de "quitar en orden" es largo y, pegado al borde derecho, se
  /// renderizaba como una cinta vertical ilegible. El margen lo obliga a
  /// maquetarse como globo ancho y centrado.
  Widget _buildBotonQuitar(BuildContext context, ThemeData theme) {
    return Tooltip(
      message: puedeEliminar
          ? AppStrings.carritoQuitar
          : AppStrings.carritoQuitarOrden,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      preferBelow: false,
      child: IconButton(
        icon: Icon(
          Icons.remove_circle_outline,
          color: puedeEliminar
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        onPressed: puedeEliminar ? () => _quitarPago(context) : null,
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
