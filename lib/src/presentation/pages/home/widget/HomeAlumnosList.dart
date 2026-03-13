import 'package:flutter/material.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/AlumnoItem.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/HomeHeaderWidget.dart';

/// Widget que muestra la lista de alumnos con pull-to-refresh.
///
/// Incluye un encabezado informativo y la lista scrolleable
/// de alumnos con soporte para actualización por deslizamiento.
class HomeAlumnosList extends StatelessWidget {
  /// Lista de alumnos a mostrar.
  final List<Alumno> alumnos;

  /// Respuesta completa con datos de familia (puede ser null).
  final AlumnoResponse? alumnosResponse;

  /// Callback que se ejecuta al hacer pull-to-refresh.
  final VoidCallback onRefresh;

  const HomeAlumnosList({
    super.key,
    required this.alumnos,
    required this.alumnosResponse,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        // Pequeño delay para mejor feedback visual
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Column(
        children: [
          // Encabezado con información de familia
          if (alumnosResponse != null)
            HomeHeaderWidget(
              alumnosResponse: alumnosResponse!,
              alumnosCount: alumnos.length,
            ),

          // Lista de alumnos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alumnos.length,
              itemBuilder: (context, index) {
                final alumno = alumnos[index];
                return AlumnoItem(alumno);
              },
            ),
          ),
        ],
      ),
    );
  }
}
