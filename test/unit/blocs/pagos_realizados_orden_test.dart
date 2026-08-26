/// Test guardián: Pagos Realizados respeta el orden del backend.
///
/// ## Qué protege
///
/// El backend devuelve los pagos descendentes por `fecha_de_pago`, del más
/// reciente al más antiguo. Verificado contra producción el 2026-08-25 con la
/// cuenta CATutorM974: los dos alumnos llegan correctamente ordenados.
///
/// La app tenía en `PagosRealizadosList` un
/// `..sort((a, b) => b.id.compareTo(a.id))` que **pisaba ese orden**. Ordenar
/// por `id` coincide con ordenar por fecha solo mientras los ids se emitan en
/// el mismo orden que los pagos, y eso no se cumple: las reinscripciones viven
/// en un rango de ids alto (15036) y las colegiaturas en uno bajo (3418), sin
/// relación con cuándo se pagó cada una.
///
/// Caso real que reprodujo el fallo, alumna LEAH:
///
/// | orden del backend | id | fecha de pago |
/// | --- | --- | --- |
/// | 1 | 3418 | 25-08-2026 11:39 |
/// | 2 | 15036 | 24-08-2026 17:28 |
///
/// Con el `sort`, el 15036 subía al primer puesto y la app mostraba **el pago
/// del 24 por encima del pago del 25**. Nada fallaba; el historial salía mal y
/// ya.
///
/// Los datos de este test son exactamente los de ese caso, para que si alguien
/// vuelve a meter un orden propio, falle con el ejemplo real.
library;

import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pago_realizado_item.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pagos_realizados_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye un pago realizado con lo mínimo para pintarlo.
EstadoDeCuenta pagoRealizado({
  required int id,
  required String descripcion,
  required String fechaDePago,
  required int numPago,
}) {
  return EstadoDeCuenta(
    id: id,
    cicloId: 2026,
    nivelId: 1,
    emisorFiscalId: 1,
    descripcionCorta: descripcion,
    total: 9770.0,
    totalFormatted: r'$9,770.00',
    fechaVencimiento: '2026-06-30',
    estadoPago: EstadoPago.pagado,
    numPago: numPago,
    numPagoActivo: false,
    aceptaPagosDiversos: false,
    estaDisponibleEnInternet: true,
    estaDisponibleEnLaAppMovil: true,
    facturaPdf: '',
    facturaXml: '',
    fechaDePago: fechaDePago,
    ticketFolio: 'T$id',
    ticketUrl: '',
  );
}

/// El caso real de LEAH: el id más alto NO es el pago más reciente.
final List<EstadoDeCuenta> pagosDeLeah = <EstadoDeCuenta>[
  pagoRealizado(
    id: 3418,
    descripcion: 'COLEGIATURA PRIMARIA Jun 26',
    fechaDePago: '25-08-2026 11:39:07',
    numPago: 10,
  ),
  pagoRealizado(
    id: 15036,
    descripcion: 'REINSCRIPCION PRIMARIA 26 / 27',
    fechaDePago: '24-08-2026 17:28:39',
    numPago: 1,
  ),
  pagoRealizado(
    id: 3417,
    descripcion: 'COLEGIATURA PRIMARIA May 26',
    fechaDePago: '17-08-2026 17:18:52',
    numPago: 9,
  ),
];

void main() {
  /// Envuelve la lista en lo mínimo para poder pintarla.
  Widget montar(List<EstadoDeCuenta> pagos) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PagosRealizadosList(pagos: pagos),
        ),
      ),
    );
  }

  /// Ids en el orden en que quedaron pintados.
  List<int> idsPintados(WidgetTester tester) {
    return tester
        .widgetList<PagoRealizadoItem>(find.byType(PagoRealizadoItem))
        .map((PagoRealizadoItem item) => item.pago.id)
        .toList();
  }

  testWidgets('respeta el orden del backend con el caso real de LEAH',
      (WidgetTester tester) async {
    await tester.pumpWidget(montar(pagosDeLeah));

    expect(
      idsPintados(tester),
      <int>[3418, 15036, 3417],
      reason: 'La lista debe pintar los pagos en el MISMO orden en que llegan '
          'del backend. Si sale [15036, 3418, 3417] es que alguien volvió a '
          'ordenar por id: el 15036 se pagó el 24 y el 3418 el 25, así que ese '
          'orden pone el pago más antiguo arriba.',
    );
  });

  testWidgets('no reordena aunque los ids lleguen de menor a mayor',
      (WidgetTester tester) async {
    final List<EstadoDeCuenta> ascendentes = <EstadoDeCuenta>[
      pagoRealizado(
        id: 1,
        descripcion: 'El más reciente',
        fechaDePago: '25-08-2026 10:00:00',
        numPago: 3,
      ),
      pagoRealizado(
        id: 2,
        descripcion: 'Intermedio',
        fechaDePago: '20-08-2026 10:00:00',
        numPago: 2,
      ),
      pagoRealizado(
        id: 3,
        descripcion: 'El más antiguo',
        fechaDePago: '15-08-2026 10:00:00',
        numPago: 1,
      ),
    ];

    await tester.pumpWidget(montar(ascendentes));

    expect(
      idsPintados(tester),
      <int>[1, 2, 3],
      reason: 'Cualquier orden propio —por id, por fecha, por lo que sea— '
          'rompe este caso. La lista solo pinta lo que recibe.',
    );
  });

  testWidgets('no modifica la lista que recibe', (WidgetTester tester) async {
    final List<EstadoDeCuenta> original = List<EstadoDeCuenta>.from(pagosDeLeah);

    await tester.pumpWidget(montar(original));

    expect(
      original.map((EstadoDeCuenta p) => p.id).toList(),
      <int>[3418, 15036, 3417],
      reason: 'Ordenar in situ la lista recibida contaminaría el estado del '
          'BLoC, que es de donde cuelga.',
    );
  });
}
