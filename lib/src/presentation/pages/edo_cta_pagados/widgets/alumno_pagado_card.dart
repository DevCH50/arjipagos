import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pagos_realizados_list.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/UserAvatar.dart';
import 'package:flutter/material.dart';

/// Tarjeta expandible de un alumno con sus pagos ya realizados.
class AlumnoPagadoCard extends StatelessWidget {
  final Alumno alumno;

  /// Folio del ticket recién pagado, si se llegó desde un push de pago exitoso.
  final String? folioDestacado;

  const AlumnoPagadoCard({
    super.key,
    required this.alumno,
    this.folioDestacado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: UserAvatar(
            urlPhoto: ApiConfig.buildUri(alumno.urlPhoto).toString(),
            nombre: alumno.nombre,
            esBaja: alumno.esBaja,
            radius: 24,
            showBorder: true,
          ),
          title: Text(
            alumno.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _subtitulo(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            PagosRealizadosList(
              pagos: alumno.estadoDeCuenta,
              folioDestacado: folioDestacado,
            ),
          ],
        ),
      ),
    );
  }

  /// Grupo del alumno; el backend puede mandarlo vacío en esta respuesta, así
  /// que en ese caso se muestra la cantidad de pagos en su lugar.
  String _subtitulo() {
    if (alumno.grupo.trim().isNotEmpty) {
      return '${AppStrings.alumnoGroupLabel} ${alumno.grupo}';
    }
    final cantidad = alumno.estadoDeCuenta.length;
    return '$cantidad ${AppStrings.edoCtaPagadosTitle.toLowerCase()}';
  }
}
