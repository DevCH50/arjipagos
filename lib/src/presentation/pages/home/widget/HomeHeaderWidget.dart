import 'package:flutter/material.dart';
import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';

/// Widget que muestra el encabezado informativo de la página Home.
///
/// Presenta chips con información relevante como el ID de familia,
/// ciclo escolar y cantidad de alumnos.
///
/// Compatible con tema claro y oscuro.
class HomeHeaderWidget extends StatelessWidget {
  /// Respuesta con los datos de alumnos y familia.
  final AlumnoResponse alumnosResponse;

  /// Cantidad de alumnos en la lista.
  final int alumnosCount;

  const HomeHeaderWidget({
    super.key,
    required this.alumnosResponse,
    required this.alumnosCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.getHomeHeaderBackground(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            label: 'Familia ID',
            value: alumnosResponse.familiaId.toString(),
            icon: Icons.family_restroom,
            isDark: isDark,
          ),
          _InfoChip(
            label: 'Ciclo Escolar',
            value: alumnosResponse.cicloPredeterminado.toString(),
            icon: Icons.calendar_today,
            isDark: isDark,
          ),
          _InfoChip(
            label: alumnosCount == 1 ? 'Alumno' : 'Alumnos',
            value: alumnosCount.toString(),
            icon: Icons.people,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Widget interno que muestra un chip con icono, valor y etiqueta.
/// Compatible con tema claro y oscuro.
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.getHomeHeaderIcon(isDark)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.getHomeHeaderText(isDark),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
