import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:arjipagos/src/presentation/pages/ticket/TicketPage.dart';
import 'package:flutter/material.dart';

/// Item individual de un pago ya realizado.
///
/// Es de solo lectura: no tiene checkbox ni alimenta al carrito. Cuando el pago
/// trae ticket, muestra un botón que abre el comprobante.
///
/// El contenido se apila en filas de ancho completo en vez de partirse en dos
/// columnas: con el botón *Ver ticket* compitiendo por el espacio horizontal, al
/// concepto le quedaba tan poco ancho que se partía en dos líneas y la fecha de
/// pago se recortaba con puntos suspensivos.
class PagoRealizadoItem extends StatelessWidget {
  final EstadoDeCuenta pago;

  const PagoRealizadoItem({
    super.key,
    required this.pago,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConceptoYMonto(theme, isDark),
          const SizedBox(height: 6),
          _buildFechaYNumPago(theme),
          if (pago.ticketFolio.isNotEmpty) _buildFolio(theme),
          const SizedBox(height: 6),
          _buildEstadoYTicket(context),
        ],
      ),
    );
  }

  /// Primera fila: concepto a la izquierda y monto a la derecha.
  ///
  /// El concepto se lleva todo el ancho sobrante, que es lo que le permite
  /// caber en una sola línea.
  Widget _buildConceptoYMonto(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            pago.descripcionAbreviada,
            // Dos líneas como red de seguridad para pantallas muy angostas o
            // con el tamaño de fuente del sistema aumentado.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          pago.totalFormatted,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.successLight : AppColors.success,
          ),
        ),
      ],
    );
  }

  /// Segunda fila: fecha de pago a la izquierda y número de pago a la derecha.
  Widget _buildFechaYNumPago(ThemeData theme) {
    return Row(
      children: [
        if (pago.fechaDePagoCorta.isNotEmpty)
          Expanded(
            child: _buildLineaConIcono(
              theme,
              Icons.event_available,
              '${AppStrings.edoCtaPagadosFechaPago} ${pago.fechaDePagoCorta}',
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 8),
        Text(
          '${AppStrings.edoCtaPagoNum}${pago.numPago}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Tercera fila: folio del ticket, a todo lo ancho.
  Widget _buildFolio(ThemeData theme) {
    return _buildLineaConIcono(
      theme,
      Icons.confirmation_number_outlined,
      '${AppStrings.edoCtaPagadosFolio} ${pago.ticketFolio}',
    );
  }

  /// Última fila: chip de estado a la izquierda y acceso al ticket a la derecha.
  Widget _buildEstadoYTicket(BuildContext context) {
    return Row(
      children: [
        // El renglón del pago realizado ya viene con su tinte verde, así que la
        // píldora se pinta en `surface` para despegarse de él; con el
        // contenedor del tema quedaría un tono sobre otro tono.
        EstadoPagoChip(estadoPago: pago.estadoPago, sobreTinte: true),
        const Spacer(),
        if (pago.tieneTicket) _buildBotonTicket(context),
      ],
    );
  }

  /// Línea de detalle con ícono, recortada si no cabe.
  Widget _buildLineaConIcono(ThemeData theme, IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icono, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón que descarga el ticket del pago y lo abre con el visor del sistema.
  Widget _buildBotonTicket(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Ruta restaurable: si Android recicla el proceso mientras el usuario
      // comparte o abre el PDF fuera, al volver reaparece el ticket y no el
      // Menú Principal. Los argumentos viajan como mapa porque el sistema solo
      // sabe guardar tipos primitivos.
      onPressed: () => Navigator.restorablePushNamed(
        context,
        'ticket',
        arguments: TicketArgs(
          url: pago.ticketUrl,
          folio: pago.ticketFolio,
        ).aMapa(),
      ),
      icon: const Icon(Icons.receipt_long, size: 18),
      label: const Text(AppStrings.edoCtaPagadosVerTicket),
    );
  }
}
