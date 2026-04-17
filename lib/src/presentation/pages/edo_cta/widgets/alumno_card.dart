import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/pagos_list.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/UserAvatar.dart';
import 'package:flutter/material.dart';

/// Tarjeta expandible de un alumno con sus pagos.
class AlumnoCard extends StatelessWidget {
  final Alumno alumno;

  const AlumnoCard({
    super.key,
    required this.alumno,
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
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: alumno.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: alumno.esBaja
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          subtitle: Text(
            '${AppStrings.alumnoGroupLabel} ${alumno.grupo}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            if (alumno.estadoDeCuenta.isEmpty)
              _buildSinPagos(theme)
            else
              PagosList(
                alumno: alumno,
                pagos: alumno.estadoDeCuenta,
              ),
          ],
        ),
      ),
    );
  }

  /// Muestra mensaje cuando el alumno no tiene pagos pendientes.
  Widget _buildSinPagos(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        AppStrings.edoCtaSinPagosPendientes,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
