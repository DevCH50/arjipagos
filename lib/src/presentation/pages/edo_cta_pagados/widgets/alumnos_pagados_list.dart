import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/alumno_pagado_card.dart';
import 'package:flutter/material.dart';

/// Lista de alumnos con sus pagos realizados.
class AlumnosPagadosList extends StatelessWidget {
  final List<Alumno> alumnos;

  const AlumnosPagadosList({
    super.key,
    required this.alumnos,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alumnos.length,
      itemBuilder: (context, index) {
        return AlumnoPagadoCard(alumno: alumnos[index]);
      },
    );
  }
}
