import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late EdoCtaListBloc bloc;
  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;
  late MockSharedPref mockSharedPref;

  setUp(() {
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();
    mockSharedPref = MockSharedPref();

    // Configurar mock de SharedPref
    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  EdoCtaListBloc createBloc() {
    return EdoCtaListBloc(
      createMockEdoCtaUseCases(getEstadosDeCuenta: mockGetEstadosDeCuenta),
      // Storage real sobre el SharedPref mockeado: así los tests del BLoC
      // también ejercitan la (de)serialización con ámbito de ciclo.
      SeleccionPagosStorage(mockSharedPref, claveSeleccion: 'seleccion_pagos_ef1'),
      emisorFiscalId: 1,
    );
  }

  group('EdoCtaListBloc', () {
    // Alumno de prueba disponible en todos los subgrupos
    final alumnoTest = TestAlumno.activo;

    test('estado inicial es correcto', () {
      bloc = createBloc();
      expect(bloc.state, const EdoCtaListState());
      expect(bloc.state.isLoading, false);
      expect(bloc.state.alumnos, null);
      expect(bloc.state.pagosSeleccionados, isEmpty);
    });

    group('EdoCtaListInitialEvent', () {

      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'emite estado con alumnos cuando la carga es exitosa',
        build: () {
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Success(EstadosDeCuentaResponse(
              alumnos: [alumnoTest],
              cicloPredeterminadoId: '1',
              familiaId: '1',
              familia: 'Familia Test',
              success: true,
              message: '',
            )),
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const EdoCtaListInitialEvent()),
        expect: () => [
          // Primer estado: isLoading = true (inicio de carga)
          isA<EdoCtaListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          // Segundo estado: datos cargados con alumnos
          isA<EdoCtaListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.alumnos, 'alumnos', isNotNull)
              .having((s) => s.alumnos!.length, 'alumnos.length', 1),
        ],
      );

      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'emite error cuando la carga falla',
        build: () {
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Error('Error de conexión'),
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const EdoCtaListInitialEvent()),
        expect: () => [
          // Primer estado: isLoading = true (inicio de carga)
          isA<EdoCtaListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          // Segundo estado: error con mensaje
          isA<EdoCtaListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', 'Error de conexión'),
        ],
      );
    });

    group('EdoCtaTogglePagoEvent', () {
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'selecciona un pago correctamente',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          isLoading: false,
          alumnos: [alumnoTest], // alumno con pagoId=1 (aceptaPagosDiversos=true)
          pagosSeleccionados: const {},
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: 1,
          pagoId: 1, // primer pago del alumno
        )),
        expect: () => [
          isA<EdoCtaListState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            {
              TestEstadoDeCuenta.cicloActual: {1: [1]},
            },
          ),
        ],
      );

      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'deselecciona un pago correctamente',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          isLoading: false,
          alumnos: [alumnoTest], // alumno con pagos id=1 e id=2
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1]},
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: 1,
          pagoId: 1,
        )),
        expect: () => [
          isA<EdoCtaListState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            isEmpty,
          ),
        ],
      );
    });

    group('EdoCtaLimpiarSeleccionEvent', () {
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'limpia todos los pagos seleccionados',
        build: () => createBloc(),
        seed: () => const EdoCtaListState(
          isLoading: false,
          pagosSeleccionados: {
            TestEstadoDeCuenta.cicloActual: {
              1: [100, 101],
              2: [200],
            },
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaLimpiarSeleccionEvent()),
        expect: () => [
          isA<EdoCtaListState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            isEmpty,
          ),
        ],
      );
    });
  });

  group('EdoCtaListState', () {
    const cicloA = TestEstadoDeCuenta.cicloActual;
    const cicloB = TestEstadoDeCuenta.cicloAnterior;

    test('isPagoSeleccionado retorna true cuando el pago está seleccionado', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {
          cicloA: {1: [100, 101]},
        },
      );
      expect(state.isPagoSeleccionado(cicloA, 1, 100), true);
      expect(state.isPagoSeleccionado(cicloA, 1, 101), true);
      expect(state.isPagoSeleccionado(cicloA, 1, 102), false);
      expect(state.isPagoSeleccionado(cicloA, 2, 100), false);
    });

    test('isPagoSeleccionado distingue el ciclo: el mismo pago en otro ciclo no cuenta', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {
          cicloA: {1: [100]},
        },
      );
      expect(state.isPagoSeleccionado(cicloA, 1, 100), true);
      expect(state.isPagoSeleccionado(cicloB, 1, 100), false);
    });

    test('cantidadPagosSeleccionados suma todos los ciclos', () {
      // Hacen falta los alumnos, no solo el mapa de selección: desde que los
      // pagos se reparten por emisor fiscal hay que mirar cada pago para saber
      // si es de esta pantalla. El mapa guarda junta la selección de los dos.
      final state = EdoCtaListState(
        alumnos: [
          alumnoConPagosPorCiclo(1, {cicloA: [100, 101], cicloB: [300]}),
          alumnoConPagosPorCiclo(2, {cicloA: [200]}),
        ],
        pagosSeleccionados: const {
          cicloA: {
            1: [100, 101],
            2: [200],
          },
          cicloB: {
            1: [300],
          },
        },
      );
      expect(state.cantidadPagosSeleccionados, 4);
    });

    test('puedeSelecionarPago respeta orden de IDs', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {
          cicloA: {1: [100]},
        },
      );
      // Puede seleccionar el siguiente (101) pero no saltar al 102
      expect(state.puedeSelecionarPago(cicloA, 1, 101, [100, 101, 102]), true);
      expect(state.puedeSelecionarPago(cicloA, 1, 102, [100, 101, 102]), false);
    });

    test('el orden ascendente se evalúa solo dentro del mismo ciclo', () {
      // El alumno no tiene nada seleccionado en el ciclo B, aunque sí en el A.
      const state = EdoCtaListState(
        pagosSeleccionados: {
          cicloA: {1: [100]},
        },
      );

      // En el ciclo B puede seleccionar su primer pago sin haber tocado el A,
      // aunque su ID (300) sea mayor que los del ciclo A.
      expect(state.puedeSelecionarPago(cicloB, 1, 300, [300, 301]), true);
      // Pero dentro del ciclo B sigue sin poder saltarse el orden.
      expect(state.puedeSelecionarPago(cicloB, 1, 301, [300, 301]), false);
    });

    test('totalSeleccionado solo suma pagos seleccionados en su propio ciclo', () {
      final alumno = Alumno(
        alumnoId: 1,
        familiaId: 1,
        familia: 'Familia Test',
        alumno: 'Test',
        apPaterno: '',
        apMaterno: '',
        nombre: 'Test',
        becaSep: '',
        becaArji: '',
        becaBach: '',
        becaSp: '',
        esBaja: false,
        grupoId: 1,
        grupo: '',
        urlPhoto: '',
        estadoDeCuenta: TestEstadoDeCuenta.listaDosCiclos,
      );

      // Se selecciona el pago id=1 (ciclo actual, $5000) y el id=10
      // (ciclo anterior, $4000).
      final state = EdoCtaListState(
        alumnos: [alumno],
        pagosSeleccionados: const {
          cicloA: {1: [1]},
          cicloB: {1: [10]},
        },
      );
      expect(state.totalSeleccionado, 9000.0);

      // Si el id=10 se registra bajo el ciclo equivocado, no debe sumarse.
      final stateMalCiclo = EdoCtaListState(
        alumnos: [alumno],
        pagosSeleccionados: const {
          cicloA: {1: [1, 10]},
        },
      );
      expect(stateMalCiclo.totalSeleccionado, 5000.0);
    });
  });
}
