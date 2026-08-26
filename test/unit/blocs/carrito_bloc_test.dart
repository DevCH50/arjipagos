import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late CarritoBloc bloc;
  late MockSharedPref mockSharedPref;
  late MockGetUserSessionUseCase mockGetUserSession;
  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;

  final testAuthResponse = TestAuthResponse.valid;
  final testAlumno = TestAlumno.activo;

  setUp(() {
    mockSharedPref = MockSharedPref();
    mockGetUserSession = MockGetUserSessionUseCase();
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();

    // Configurar mocks por defecto
    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  CarritoBloc createBloc() {
    return CarritoBloc(
      // Storage real sobre el SharedPref mockeado: los tests del BLoC también
      // ejercitan la (de)serialización con ámbito de ciclo.
      seleccionStorage: SeleccionPagosStorage(mockSharedPref, claveSeleccion: 'seleccion_pagos_ef1'),
      authUseCases: createMockAuthUseCases(getUserSession: mockGetUserSession),
      edoCtaUseCases: createMockEdoCtaUseCases(
        getEstadosDeCuenta: mockGetEstadosDeCuenta,
      ),
      emisorFiscalId: 1,
    );
  }

  group('CarritoBloc', () {
    test('estado inicial es correcto', () {
      bloc = createBloc();
      expect(bloc.state, const CarritoState());
      expect(bloc.state.isLoading, false);
      expect(bloc.state.itemsCarrito, isEmpty);
    });

    group('CarritoInitialEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'carga carrito vacío cuando no hay pagos seleccionados',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const CarritoInitialEvent()),
        expect: () => [
          isA<CarritoState>().having((s) => s.isLoading, 'isLoading', true),
          isA<CarritoState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.itemsCarrito, 'itemsCarrito', isEmpty),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'carga carrito con pagos cuando hay selección en storage',
        build: () {
          when(() => mockSharedPref.readMap(any())).thenAnswer(
            (_) async => {'1': [100]},
          );
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Success(EstadosDeCuentaResponse(
              alumnos: [testAlumno],
              cicloPredeterminadoId: '1',
              familiaId: '1',
              familia: 'Test',
              success: true,
              message: '',
            )),
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const CarritoInitialEvent()),
        expect: () => [
          isA<CarritoState>().having((s) => s.isLoading, 'isLoading', true),
          isA<CarritoState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.alumnos, 'alumnos', isNotNull),
        ],
      );
    });

    group('CarritoQuitarPagoEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'quita un pago del carrito',
        build: () => createBloc(),
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1, 2]},
          },
        ),
        act: (bloc) => bloc.add(const CarritoQuitarPagoEvent(
          alumnoId: 1,
          pagoId: 2,
        )),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            {
              TestEstadoDeCuenta.cicloActual: {1: [1]},
            },
          ),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'elimina el alumno cuando no quedan pagos',
        build: () => createBloc(),
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1]},
          },
        ),
        act: (bloc) => bloc.add(const CarritoQuitarPagoEvent(
          alumnoId: 1,
          pagoId: 1,
        )),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            isEmpty,
          ),
        ],
      );
    });

    group('CarritoLimpiarEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'vacía el carrito completamente',
        build: () => createBloc(),
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1, 2]},
          },
        ),
        act: (bloc) => bloc.add(const CarritoLimpiarEvent()),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            isEmpty,
          ),
        ],
      );
    });

    group('CarritoPagarEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'emite error cuando no hay pagos seleccionados',
        build: () => createBloc(),
        seed: () => const CarritoState(pagosSeleccionados: {}),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            'No hay pagos seleccionados',
          ),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'procesa pago exitosamente',
        build: () {
          when(() => mockGetUserSession.run()).thenAnswer(
            (_) async => testAuthResponse,
          );
          return createBloc();
        },
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1]},
          },
        ),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.isProcesandoPago,
            'isProcesandoPago',
            true,
          ),
          isA<CarritoState>()
              .having((s) => s.isProcesandoPago, 'isProcesandoPago', false)
              .having((s) => s.pagoData, 'pagoData', isNotNull),
        ],
      );
    });

    group('CarritoPagoExitosoEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'limpia el carrito después de pago exitoso',
        build: () => createBloc(),
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {
            TestEstadoDeCuenta.cicloActual: {1: [1]},
          },
        ),
        act: (bloc) => bloc.add(const CarritoPagoExitosoEvent()),
        expect: () => [
          isA<CarritoState>()
              .having((s) => s.pagosSeleccionados, 'pagosSeleccionados', isEmpty)
              .having((s) => s.pagoExitoso, 'pagoExitoso', true),
        ],
      );
    });
  });

  group('CarritoState', () {
    test('totalAPagar calcula correctamente', () {
      final state = CarritoState(
        alumnos: [testAlumno],
        pagosSeleccionados: const {
          TestEstadoDeCuenta.cicloActual: {1: [1, 2]},
        },
      );
      // pago id=1: 5000.0, pago id=2: 4500.0
      expect(state.totalAPagar, 9500.0);
    });

    test('cantidadPagos cuenta correctamente', () {
      final state = CarritoState(
        alumnos: [testAlumno],
        pagosSeleccionados: const {
          TestEstadoDeCuenta.cicloActual: {1: [1, 2]},
        },
      );
      expect(state.cantidadPagos, 2);
    });

    test('referenciaPago genera formato correcto', () {
      final state = CarritoState(
        alumnos: [testAlumno],
        pagosSeleccionados: const {
          TestEstadoDeCuenta.cicloActual: {1: [1, 2]},
        },
      );
      expect(state.referenciaPago, AppConstants.generarReferencia([1, 2]));
    });
  });

  group('CarritoState — ámbito de ciclo', () {
    const cicloA = TestEstadoDeCuenta.cicloActual;
    const cicloB = TestEstadoDeCuenta.cicloAnterior;

    /// Alumno con pagos de dos ciclos: ids 1 y 2 en el ciclo actual, id 10 en
    /// el anterior.
    Alumno alumnoDosCiclos() => Alumno(
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

    test('itemsCarrito incluye pagos de varios ciclos del mismo alumno', () {
      final state = CarritoState(
        alumnos: [alumnoDosCiclos()],
        pagosSeleccionados: const {
          cicloA: {1: [1]},
          cicloB: {1: [10]},
        },
      );

      expect(state.itemsCarrito, hasLength(1));
      expect(state.itemsCarrito.first.pagos.map((p) => p.id), [1, 10]);
      expect(state.cantidadPagos, 2);
    });

    test('puedeEliminarPago usa el máximo de cada ciclo, no el global', () {
      final state = CarritoState(
        alumnos: [alumnoDosCiclos()],
        pagosSeleccionados: const {
          cicloA: {1: [1, 2]},
          cicloB: {1: [10]},
        },
      );
      final item = state.itemsCarrito.first;

      // En el ciclo actual el máximo es el 2: el 1 no se puede quitar todavía.
      expect(item.puedeEliminarPago(2), true);
      expect(item.puedeEliminarPago(1), false);

      // El 10 es el único de su ciclo, así que es su propio máximo y se puede
      // quitar aunque su ID sea el más alto de toda la lista.
      expect(item.puedeEliminarPago(10), true);
    });

    blocTest<CarritoBloc, CarritoState>(
      'quitar un pago de un ciclo no toca la selección del otro',
      build: () => createBloc(),
      seed: () => CarritoState(
        alumnos: [alumnoDosCiclos()],
        pagosSeleccionados: const {
          cicloA: {1: [1, 2]},
          cicloB: {1: [10]},
        },
      ),
      act: (bloc) => bloc.add(const CarritoQuitarPagoEvent(
        alumnoId: 1,
        pagoId: 2,
      )),
      expect: () => [
        isA<CarritoState>().having(
          (s) => s.pagosSeleccionados,
          'pagosSeleccionados',
          {
            cicloA: {1: [1]},
            cicloB: {1: [10]},
          },
        ),
      ],
    );

    blocTest<CarritoBloc, CarritoState>(
      'al vaciar el ciclo se elimina su entrada y sobrevive el otro',
      build: () => createBloc(),
      seed: () => CarritoState(
        alumnos: [alumnoDosCiclos()],
        pagosSeleccionados: const {
          cicloA: {1: [1]},
          cicloB: {1: [10]},
        },
      ),
      act: (bloc) => bloc.add(const CarritoQuitarPagoEvent(
        alumnoId: 1,
        pagoId: 1,
      )),
      expect: () => [
        isA<CarritoState>().having(
          (s) => s.pagosSeleccionados,
          'pagosSeleccionados',
          {
            cicloB: {1: [10]},
          },
        ),
      ],
    );
  });
}
