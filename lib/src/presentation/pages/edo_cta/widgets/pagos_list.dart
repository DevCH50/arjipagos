import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/pago_item.dart';
import 'package:flutter/material.dart';

/// Lista de pagos de un alumno.
/// Filtra solo los pagos disponibles en internet.
class PagosList extends StatelessWidget {
  final Alumno alumno;
  final List<EstadoDeCuenta> pagos;

  const PagosList({
    super.key,
    required this.alumno,
    required this.pagos,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar solo los pagos disponibles en internet y ordenar por ID
    final pagosDisponibles = pagos
        .where((p) => p.estaDisponibleEnInternet)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (pagosDisponibles.isEmpty) {
      return _buildMensajeVacio(context);
    }

    return Column(
      children: [
        const Divider(height: 1),
        ...pagosDisponibles.map((pago) => PagoItem(
          alumno: alumno,
          pago: pago,
          pagosDisponibles: pagosDisponibles,
        )),
      ],
    );
  }

  /// Muestra mensaje cuando no hay pagos disponibles en línea.
  Widget _buildMensajeVacio(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        AppStrings.edoCtaSinPagosEnLinea,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
