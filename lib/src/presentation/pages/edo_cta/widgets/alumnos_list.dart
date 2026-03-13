import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/alumno_card.dart';
import 'package:flutter/material.dart';

/// Lista de alumnos con sus pagos pendientes.
class AlumnosList extends StatelessWidget {
  final List<Alumno> alumnos;

  const AlumnosList({
    super.key,
    required this.alumnos,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alumnos.length,
      itemBuilder: (context, index) {
        return AlumnoCard(alumno: alumnos[index]);
      },
    );
  }
}
