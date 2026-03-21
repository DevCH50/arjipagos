import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
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
      mockSharedPref,
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
            (_) async => Success(EstatodosDeCuentaResponse(
              alumnos: [alumnoTest],
              cicloPredeterminadoId: '1',
              familiaId: '1',
              familia: 'Familia Test',
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
            {1: [1]},
          ),
        ],
      );

      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'deselecciona un pago correctamente',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          isLoading: false,
          alumnos: [alumnoTest], // alumno con pagos id=1 e id=2
          pagosSeleccionados: const {1: [1]},
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
            1: [100, 101],
            2: [200],
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
    test('isPagoSeleccionado retorna true cuando el pago está seleccionado', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {1: [100, 101]},
      );
      expect(state.isPagoSeleccionado(1, 100), true);
      expect(state.isPagoSeleccionado(1, 101), true);
      expect(state.isPagoSeleccionado(1, 102), false);
      expect(state.isPagoSeleccionado(2, 100), false);
    });

    test('cantidadPagosSeleccionados cuenta correctamente', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {
          1: [100, 101],
          2: [200],
        },
      );
      expect(state.cantidadPagosSeleccionados, 3);
    });

    test('puedeSelecionarPago respeta orden de IDs', () {
      const state = EdoCtaListState(
        pagosSeleccionados: {1: [100]},
      );
      // Puede seleccionar el siguiente (101) pero no saltar al 102
      expect(state.puedeSelecionarPago(1, 101, [100, 101, 102]), true);
      expect(state.puedeSelecionarPago(1, 102, [100, 101, 102]), false);
    });
  });
}
