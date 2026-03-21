import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
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
      sharedPref: mockSharedPref,
      authUseCases: createMockAuthUseCases(getUserSession: mockGetUserSession),
      edoCtaUseCases: createMockEdoCtaUseCases(
        getEstadosDeCuenta: mockGetEstadosDeCuenta,
      ),
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
            (_) async => Success(EstatodosDeCuentaResponse(
              alumnos: [testAlumno],
              cicloPredeterminadoId: '1',
              familiaId: '1',
              familia: 'Test',
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
          pagosSeleccionados: const {1: [1, 2]},
        ),
        act: (bloc) => bloc.add(const CarritoQuitarPagoEvent(
          alumnoId: 1,
          pagoId: 2,
        )),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.pagosSeleccionados,
            'pagosSeleccionados',
            {1: [1]},
          ),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'elimina el alumno cuando no quedan pagos',
        build: () => createBloc(),
        seed: () => CarritoState(
          alumnos: [testAlumno],
          pagosSeleccionados: const {1: [1]},
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
          pagosSeleccionados: const {1: [1, 2]},
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
          pagosSeleccionados: const {1: [1]},
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
          pagosSeleccionados: const {1: [1]},
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
        pagosSeleccionados: const {1: [1, 2]},
      );
      // pago id=1: 5000.0, pago id=2: 4500.0
      expect(state.totalAPagar, 9500.0);
    });

    test('cantidadPagos cuenta correctamente', () {
      final state = CarritoState(
        alumnos: [testAlumno],
        pagosSeleccionados: const {1: [1, 2]},
      );
      expect(state.cantidadPagos, 2);
    });

    test('referenciaPago genera formato correcto', () {
      final state = CarritoState(
        alumnos: [testAlumno],
        pagosSeleccionados: const {1: [1, 2]},
      );
      expect(state.referenciaPago, contains('D'));
    });
  });
}
