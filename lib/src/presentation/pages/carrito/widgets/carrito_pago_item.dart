import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:arjipagos/src/presentation/widgets/ConceptoPago.dart';
import 'package:arjipagos/src/presentation/widgets/FilaAdaptable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Item individual de un pago en el carrito.
///
/// - Si aceptaPagosDiversos = false: Se puede eliminar libremente.
/// - Si aceptaPagosDiversos = true: Solo el pago con ID más alto se puede eliminar.
///
/// Se maqueta igual que `PagoItem` de Pagos Pendientes, en tres renglones: el
/// concepto se queda con la línea entera —así cabe en una sola y no se
/// recorta—, debajo van la fecha y el importe, y al final el chip de estado con
/// el botón de quitar. El importe usa el tamaño del concepto en negrita, para
/// que las dos pantallas se lean igual y el renglón se vea congruente.
///
/// Nada de `ListTile`: su `trailing` recibe un ancho acotado y el importe junto
/// al botón de quitar desbordaban por fracciones de pixel en pantallas
/// angostas.
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: _buildContenido(context, theme),
    );
  }

  /// Contenido del pago: tres renglones iguales para todos los items.
  Widget _buildContenido(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConceptoPago(texto: pago.descripcionCompleta),
        const SizedBox(height: 6),
        FilaAdaptable(
          izquierda: _buildVencimiento(theme),
          derecha: _buildMonto(theme),
          textoDerecha: pago.totalFormatted,
          estiloDerecha: _estiloMonto(theme),
        ),
        const SizedBox(height: 6),
        FilaAdaptable(
          // El chip es una píldora: en un `Expanded` se estiraría a todo el
          // ancho, así que se ancla a la izquierda con su tamaño natural.
          izquierda: Align(
            alignment: Alignment.centerLeft,
            child: EstadoPagoChip(estadoPago: pago.estadoPago),
          ),
          derecha: _buildBotonQuitar(context, theme),
          // El botón no es texto: se mide como una cadena vacía para que la
          // fila nunca lo mande solo a otra línea; su ancho es fijo y pequeño.
          textoDerecha: '',
          estiloDerecha: theme.textTheme.bodySmall!,
        ),
      ],
    );
  }

  /// Construye la fila de fecha de vencimiento.
  Widget _buildVencimiento(ThemeData theme) {
    final estilo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        // La fecha se lee completa: si no cabe se encoge, nunca se recorta.
        // El ajuste es uniforme entre renglones porque todas las fechas del
        // backend tienen el mismo formato y miden lo mismo.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppStrings.edoCtaVence} ${pago.fechaVencimiento}',
              maxLines: 1,
              softWrap: false,
              style: estilo,
            ),
          ),
        ),
      ],
    );
  }

  /// Importe del pago.
  Widget _buildMonto(ThemeData theme) {
    return Text(
      pago.totalFormatted,
      // maxLines + softWrap: false evita que el importe se parta carácter por
      // carácter; la fila adaptable ya le garantiza su ancho.
      maxLines: 1,
      softWrap: false,
      style: _estiloMonto(theme),
    );
  }

  /// Estilo del importe; se comparte con la medición de la fila adaptable.
  ///
  /// Mismo tamaño que el concepto y en negrita: destaca por peso, no por ser
  /// más grande, igual que en Pagos Pendientes.
  TextStyle _estiloMonto(ThemeData theme) {
    return theme.textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
      // Cifras de ancho fijo: los importes alinean en columna en vez de bailar
      // según los dígitos que le toquen a cada renglón.
      fontFeatures: const [FontFeature.tabularFigures()],
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
        // Candado en vez de un botón de quitar apagado: un control que no
        // responde parece un fallo, un candado explica que ese pago sostiene
        // a los anteriores del ciclo.
        icon: Icon(
          puedeEliminar ? Icons.remove_circle_outline : Icons.lock_outline,
          color: puedeEliminar
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.32),
        ),
        onPressed: puedeEliminar ? () => _quitarPago(context) : null,
      ),
    );
  }

  void _quitarPago(BuildContext context) {
    context.read<CarritoBloc>().add(
      CarritoQuitarPagoEvent(alumnoId: alumnoId, pagoId: pago.id),
    );
  }
}
