import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pago_realizado_item.dart';
import 'package:flutter/material.dart';

/// Lista de pagos ya realizados de un alumno.
///
/// A diferencia de los pendientes, aquí no se filtra por
/// `estaDisponibleEnInternet`: el pago ya ocurrió y debe poder consultarse
/// aunque en su momento no se ofreciera en línea.
///
/// ## El orden es el del backend. NO se reordena aquí.
///
/// El backend devuelve los pagos descendentes por `fecha_de_pago`, del más
/// reciente al más antiguo, que es como se espera ver un historial. Esta lista
/// los pinta **en el orden en que llegan** y no le añade criterio propio.
///
/// **Hubo aquí un `..sort((a, b) => b.id.compareTo(a.id))` y estaba mal.**
/// Ordenar por `id` da el mismo resultado que ordenar por fecha solo mientras
/// los ids se emitan en el mismo orden que los pagos, y eso no se cumple:
/// las reinscripciones viven en un rango de ids muy alto (15036) y las
/// colegiaturas en uno bajo (3418), sin relación con cuándo se pagó cada una.
///
/// Caso real capturado el 2026-08-25 en la cuenta CATutorM974, alumna LEAH:
///
/// | orden del backend | id | fecha de pago |
/// | --- | --- | --- |
/// | 1 | 3418 | 25-08-2026 11:39 |
/// | 2 | 15036 | 24-08-2026 17:28 |
///
/// Al ordenar por `id` descendente, el 15036 subía al primer puesto y la app
/// mostraba **el pago del 24 por encima del pago del 25**. El historial salía
/// desordenado sin que nada fallara.
///
/// Si algún día el orden se ve mal, el sitio donde mirar es el backend —no
/// este archivo—: la app se limita a respetar lo que recibe. Hay test guardián
/// en `test/unit/blocs/pagos_realizados_orden_test.dart`.
class PagosRealizadosList extends StatelessWidget {
  final List<EstadoDeCuenta> pagos;

  /// Folio del ticket recién pagado, si se llegó desde un push de pago exitoso.
  final String? folioDestacado;

  const PagosRealizadosList({
    super.key,
    required this.pagos,
    this.folioDestacado,
  });

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return _buildMensajeVacio(context);
    }

    return Column(
      children: [
        const Divider(height: 1),
        ...pagos.map((pago) => PagoRealizadoItem(
              pago: pago,
              folioDestacado: folioDestacado,
            )),
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
