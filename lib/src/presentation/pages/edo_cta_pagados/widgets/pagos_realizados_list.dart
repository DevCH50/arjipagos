import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pago_realizado_item.dart';
import 'package:flutter/material.dart';

/// Lista de pagos ya realizados de un alumno.
///
/// A diferencia de los pendientes, aquí no se filtra por
/// `estaDisponibleEnInternet`: el pago ya ocurrió y debe poder consultarse
/// aunque en su momento no se ofreciera en línea. El orden es del más reciente
/// al más antiguo, que es como el usuario espera ver un historial.
class PagosRealizadosList extends StatelessWidget {
  final List<EstadoDeCuenta> pagos;

  const PagosRealizadosList({
    super.key,
    required this.pagos,
  });

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return _buildMensajeVacio(context);
    }

    final pagosOrdenados = List<EstadoDeCuenta>.from(pagos)
      ..sort((a, b) => b.id.compareTo(a.id));

    return Column(
      children: [
        const Divider(height: 1),
        ...pagosOrdenados.map((pago) => PagoRealizadoItem(pago: pago)),
      ],
    );
  }

  /// Mensaje mostrado cuando el alumno no tiene pagos realizados.
  Widget _buildMensajeVacio(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        AppStrings.edoCtaPagadosSinPagosAlumno,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
