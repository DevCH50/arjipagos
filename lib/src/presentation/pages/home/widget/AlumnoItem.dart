import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/UserAvatar.dart';
import 'package:flutter/material.dart';

/// Widget que muestra la información de un alumno en una tarjeta.
///
/// Compatible con tema claro y oscuro.
class AlumnoItem extends StatelessWidget {
  final Alumno alumno;

  const AlumnoItem(this.alumno, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: UserAvatar(
          urlPhoto: ApiConfig.buildUri(alumno.urlPhoto).toString(),
          nombre: alumno.alumno,
          esBaja: alumno.esBaja,
          radius: 24,
          showBorder: true,
        ),
        title: Text(
          alumno.alumno,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: alumno.esBaja ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Grupo: ${alumno.grupo}'),
            if (alumno.esBaja)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    AppStrings.alumnoBaja,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getAlumnoBajaText(isDark),
                    ),
                  ),
                  backgroundColor: AppColors.getAlumnoBajaBackground(isDark),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showHomeDetails(context, alumno),
      ),
    );
  }

  void _showHomeDetails(BuildContext context, Alumno alumno) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            UserAvatar(
              urlPhoto: ApiConfig.buildUri(alumno.urlPhoto).toString(),
              nombre: alumno.alumno,
              esBaja: alumno.esBaja,
              radius: 20,
              showBorder: true,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(alumno.alumno, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, 'ID:', alumno.alumnoId.toString()),
              _buildDetailRow(context, 'Grupo:', alumno.grupo),
              const Divider(),
              Text(
                'Becas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(context, 'SEP:', alumno.becaSep),
              _buildDetailRow(context, 'ARJI:', alumno.becaArji),
              _buildDetailRow(context, 'Bach:', alumno.becaBach),
              _buildDetailRow(context, 'SP:', alumno.becaSp),
              const Divider(),
              _buildDetailRow(
                context,
                'Estado:',
                alumno.esBaja ? '❌ Baja' : '✅ Activo',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
