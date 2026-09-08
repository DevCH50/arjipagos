import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/AmbitoDeSeleccion.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

/// La regla de pagar en orden se aplica **dentro de cada concepto**, no dentro
/// del ciclo entero.
///
/// El caso que lo destapó (08-sep-2026, usuario ArjiNIP113, alumna IVANA): sus
/// parcialidades de `COLEGIATURA PREESCOLAR` tienen ids más bajos que las de
/// `EXTENSION DE HORARIO PREESCOLAR`, así que la app le exigía liquidar toda la
/// colegiatura antes de dejarle tocar la extensión de horario. Son dos cargos
/// distintos del catálogo y no dependen uno del otro.
///
/// El ámbito lo define `ambitoDeSeleccion`: ciclo, emisor, concepto (`pagoId`)
/// y tipo de deuda (`deudaAnterior`).
void main() {
  const int alumnoId = 1;
  const int ciclo = TestEstadoDeCuenta.cicloActual;

  // Los dos conceptos de IVANA. Los ids de COLEGIATURA van por debajo de los de
  // EXTENSION a propósito: es lo que provocaba el bloqueo.
  const int colegiatura = 900;
  const int extensionHorario = 901;

  /// Las parcialidades de un concepto, con `num_pago` correlativo y la primera
  /// marcada como activa, tal como las manda el backend.
  List<EstadoDeCuenta> parcialidades({
    required int pagoId,
    required List<int> ids,
    bool deudaAnterior = false,
  }) {
    return [
      for (int i = 0; i < ids.length; i++)
        pagoDePrueba(
          id: ids[i],
          pagoId: pagoId,
          deudaAnterior: deudaAnterior,
          numPago: i + 1,
          numPagoActivo: i == 0,
        ),
    ];
  }

  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;
  late MockSharedPref mockSharedPref;

  setUp(() {
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();
    mockSharedPref = MockSharedPref();
    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  /// BLoC de "Pagos Pendientes" ya cargado con [pagos] para un solo alumno.
  Future<EdoCtaListBloc> blocCargado(
    List<EstadoDeCuenta> pagos, {
    int emisorFiscalId = 1,
  }) async {
    final Alumno alumno = alumnoConPagos(alumnoId, pagos);
    when(
      () => mockGetEstadosDeCuenta.run(
        emisorFiscalId: any(named: 'emisorFiscalId'),
      ),
    ).thenAnswer(
      (_) async => Success(
        EstadosDeCuentaResponse(
          alumnos: [alumno],
          cicloPredeterminadoId: '$ciclo',
          familiaId: '1',
          familia: 'Familia Test',
          success: true,
          message: '',
        ),
      ),
    );

    final bloc = EdoCtaListBloc(
      createMockEdoCtaUseCases(getEstadosDeCuenta: mockGetEstadosDeCuenta),
      SeleccionPagosStorage(
        mockSharedPref,
        claveSeleccion: 'seleccion_pagos_ef$emisorFiscalId',
      ),
      emisorFiscalId: emisorFiscalId,
    );
    bloc.add(const EdoCtaListInitialEvent());
    await Future<void>.delayed(Duration.zero);
    return bloc;
  }

  group('ambitoDeSeleccion', () {
    test('cambia si cambia cualquiera de sus cuatro piezas', () {
      final base = pagoDePrueba(id: 1, pagoId: colegiatura);

      // Guardián: si alguna de estas cuatro se cae de la clave, dos pagos que
      // no tienen nada que ver vuelven a condicionarse entre sí.
      expect(
        ambitoDeSeleccion(base),
        isNot(
          equals(
            ambitoDeSeleccion(
              pagoDePrueba(id: 1, pagoId: colegiatura, cicloId: ciclo + 1),
            ),
          ),
        ),
        reason: 'el ciclo tiene que separar ámbitos',
      );
      expect(
        ambitoDeSeleccion(base),
        isNot(
          equals(
            ambitoDeSeleccion(
              pagoDePrueba(id: 1, pagoId: colegiatura, emisorFiscalId: 2),
            ),
          ),
        ),
        reason: 'el emisor tiene que separar ámbitos',
      );
      expect(
        ambitoDeSeleccion(base),
        isNot(
          equals(
            ambitoDeSeleccion(pagoDePrueba(id: 1, pagoId: extensionHorario)),
          ),
        ),
        reason: 'el concepto tiene que separar ámbitos',
      );
      expect(
        ambitoDeSeleccion(base),
        isNot(
          equals(
            ambitoDeSeleccion(
              pagoDePrueba(id: 1, pagoId: colegiatura, deudaAnterior: true),
            ),
          ),
        ),
        reason: 'la deuda anterior tiene que separar ámbitos',
      );
    });

    test('dos parcialidades del mismo cargo comparten ámbito', () {
      final pagos = parcialidades(pagoId: colegiatura, ids: [100, 101]);
      expect(ambitoDeSeleccion(pagos[0]), equals(ambitoDeSeleccion(pagos[1])));
      expect(pagos.idsDelMismoAmbitoQue(pagos[0]), equals([100, 101]));
    });
  });

  group('Estados de Cuenta — selección', () {
    test(
      'el primer pago de un concepto no depende del otro concepto',
      () async {
        // Caso IVANA: COLEGIATURA (100-104) y EXTENSION DE HORARIO (200-204).
        final bloc = await blocCargado([
          ...parcialidades(pagoId: colegiatura, ids: [100, 101, 102]),
          ...parcialidades(pagoId: extensionHorario, ids: [200, 201, 202]),
        ]);

        bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 200));
        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.state.pagosDe(ciclo, alumnoId),
          equals([200]),
          reason: 'la extensión de horario se paga sin liquidar la colegiatura',
        );
        await bloc.close();
      },
    );

    test('dentro de un concepto se sigue exigiendo el orden', () async {
      final bloc = await blocCargado([
        ...parcialidades(pagoId: colegiatura, ids: [100, 101, 102]),
        ...parcialidades(pagoId: extensionHorario, ids: [200, 201, 202]),
      ]);

      // 202 es la tercera parcialidad de la extensión: sin la 200 y la 201 no
      // se puede marcar.
      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 202));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pagosDe(ciclo, alumnoId), isEmpty);

      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 200));
      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 201));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pagosDe(ciclo, alumnoId), equals([200, 201]));
      await bloc.close();
    });

    test('deseleccionar arrastra solo dentro de su concepto', () async {
      final bloc = await blocCargado([
        ...parcialidades(pagoId: colegiatura, ids: [100, 101]),
        ...parcialidades(pagoId: extensionHorario, ids: [200, 201]),
      ]);

      for (final id in [100, 101, 200, 201]) {
        bloc.add(EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: id));
      }
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pagosDe(ciclo, alumnoId), equals([100, 101, 200, 201]));

      // Quitar la primera de la extensión arrastra la 201, y deja intacta la
      // colegiatura: antes se llevaba por delante todo lo de id mayor.
      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 200));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pagosDe(ciclo, alumnoId), equals([100, 101]));
      await bloc.close();
    });

    test('una deuda anterior del mismo cargo es otra fila aparte', () async {
      // Mismo ciclo y mismo `pago_id`; lo único que cambia es `deuda_anterior`.
      // El backend no las separa —agrupa solo por cargo y emisor—, así que sin
      // esta pieza del ámbito la deuda vieja bloquearía el mes en curso.
      final bloc = await blocCargado([
        ...parcialidades(
          pagoId: colegiatura,
          ids: [50, 51],
          deudaAnterior: true,
        ),
        ...parcialidades(pagoId: colegiatura, ids: [100, 101]),
      ]);

      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 100));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.pagosDe(ciclo, alumnoId), equals([100]));
      await bloc.close();
    });

    test('Otros pagos se comporta igual que Pagos Pendientes', () async {
      // La corrección no es de una pantalla: las dos comparten endpoint,
      // servicio y código de selección, y solo cambia el emisor.
      final bloc = await blocCargado([
        ...parcialidades(
          pagoId: colegiatura,
          ids: [100, 101],
        ).map((p) => p..emisorFiscalId = 2),
        ...parcialidades(
          pagoId: extensionHorario,
          ids: [200, 201],
        ).map((p) => p..emisorFiscalId = 2),
      ], emisorFiscalId: 2);

      bloc.add(const EdoCtaTogglePagoEvent(alumnoId: alumnoId, pagoId: 200));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.pagosDe(ciclo, alumnoId), equals([200]));
      await bloc.close();
    });
  });

  group('Carrito — quitar', () {
    test('se puede quitar la última parcialidad de cada concepto', () {
      final item = CarritoItem(
        alumno: alumnoConPagos(alumnoId, const []),
        pagos: [
          ...parcialidades(pagoId: colegiatura, ids: [100, 101]),
          ...parcialidades(pagoId: extensionHorario, ids: [200, 201]),
        ],
      );

      // La 101 es la última de la colegiatura aunque haya ids más altos en el
      // carrito: son de otro concepto y no la sostienen.
      expect(item.puedeEliminarPago(101), isTrue);
      expect(item.puedeEliminarPago(100), isFalse);
      expect(item.puedeEliminarPago(201), isTrue);
      expect(item.puedeEliminarPago(200), isFalse);
    });
  });
}
