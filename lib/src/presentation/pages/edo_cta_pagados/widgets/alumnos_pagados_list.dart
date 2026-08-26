import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/alumno_pagado_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lista de alumnos con sus pagos realizados.
///
/// Cuando llega un push de pago exitoso con `alumno_id`, se desplaza hasta la
/// tarjeta de ese alumno y la resalta un momento. Las tarjetas ya nacen
/// abiertas, así que no hay nada que expandir: basta con llevar la vista y
/// señalar cuál es.
class AlumnosPagadosList extends StatefulWidget {
  final List<Alumno> alumnos;

  /// Alumno al que desplazarse, o `null` si no hay que destacar a nadie.
  final int? alumnoDestacadoId;

  /// Folio del ticket recién pagado, para marcar sus renglones. Suelen ser
  /// varios: un mismo folio cubre todos los pagos que entraron en el cobro.
  final String? folioDestacado;

  const AlumnosPagadosList({
    super.key,
    required this.alumnos,
    this.alumnoDestacadoId,
    this.folioDestacado,
  });

  @override
  State<AlumnosPagadosList> createState() => _AlumnosPagadosListState();
}

class _AlumnosPagadosListState extends State<AlumnosPagadosList> {
  /// Cuánto se queda encendido el resalte antes de apagarse solo.
  static const Duration _duracionResalte = Duration(seconds: 3);

  /// Una clave por alumno, para poder llevar la vista hasta su tarjeta.
  final Map<int, GlobalKey> _clavesPorAlumno = {};

  @override
  void initState() {
    super.initState();
    _irAlDestacado();
  }

  @override
  void didUpdateWidget(AlumnosPagadosList anterior) {
    super.didUpdateWidget(anterior);
    // Solo cuando cambia el alumno señalado: si no, cada reconstrucción de la
    // lista volvería a mover la vista bajo los dedos del usuario.
    if (anterior.alumnoDestacadoId != widget.alumnoDestacadoId) {
      _irAlDestacado();
    }
  }

  /// Desplaza la vista hasta la tarjeta del alumno destacado y programa el
  /// apagado del resalte.
  void _irAlDestacado() {
    final int? destacado = widget.alumnoDestacadoId;
    if (destacado == null) {
      return;
    }

    // Tras el primer fotograma: antes de él la tarjeta todavía no existe, así
    // que su clave no tiene contexto al que desplazarse.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final BuildContext? destino = _clavesPorAlumno[destacado]?.currentContext;
      if (destino != null) {
        await Scrollable.ensureVisible(
          destino,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }

      await Future.delayed(_duracionResalte);
      if (!mounted) {
        return;
      }
      context
          .read<EdoCtaPagadosBloc>()
          .add(const EdoCtaPagadosDestacadoAtendidoEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.alumnos.length,
      itemBuilder: (context, index) {
        final Alumno alumno = widget.alumnos[index];
        return _TarjetaResaltable(
          key: _clavesPorAlumno.putIfAbsent(alumno.alumnoId, GlobalKey.new),
          alumno: alumno,
          resaltada: alumno.alumnoId == widget.alumnoDestacadoId,
          folioDestacado: widget.folioDestacado,
        );
      },
    );
  }
}

/// Envuelve una tarjeta de alumno para poder resaltarla al llegar desde un push.
///
/// El resalte es un halo alrededor, no un cambio de fondo: así se lee igual en
/// tema claro y en oscuro, y no compite con los colores de la propia tarjeta.
class _TarjetaResaltable extends StatelessWidget {
  final Alumno alumno;
  final bool resaltada;
  final String? folioDestacado;

  const _TarjetaResaltable({
    super.key,
    required this.alumno,
    required this.resaltada,
    this.folioDestacado,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resaltada ? colores.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: AlumnoPagadoCard(
        alumno: alumno,
        folioDestacado: folioDestacado,
      ),
    );
  }
}
