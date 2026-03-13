import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_pago_item.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/UserAvatar.dart';
import 'package:flutter/material.dart';

/// Tarjeta de un alumno con sus pagos en el carrito.
class CarritoAlumnoCard extends StatelessWidget {
  final CarritoItem item;

  const CarritoAlumnoCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ordenar pagos de mayor a menor ID para eliminar en orden
    final pagosOrdenados = item.pagos.toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          ...pagosOrdenados.map((pago) => CarritoPagoItem(
            alumnoId: item.alumno.alumnoId,
            pago: pago,
            puedeEliminar: item.puedeEliminarPago(pago.id),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return ListTile(
      leading: UserAvatar(
        urlPhoto: ApiConfig.buildUri(item.alumno.urlPhoto).toString(),
        nombre: item.alumno.alumno,
        esBaja: item.alumno.esBaja,
        radius: 24,
        showBorder: true,
      ),
      title: Text(
        item.alumno.alumno,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Grupo: ${item.alumno.grupo}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _formatearMonto(item.subtotal),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
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
