/// Tests para la validación de longitud de referencia de pago en CarritoState
/// y CarritoBloc.
///
/// Cubre:
/// - [CarritoState.referenciaValida] y [CarritoState.longitudReferencia] (unit).
/// - [CarritoBloc._onPagar]: bloqueo cuando referencia > 30 chars.
/// - [CarritoBloc._onInitial]: advertencia defensiva cuando la referencia
///   cargada del storage excede el límite.
///
/// IDs de prueba:
///   5 IDs de 5 dígitos → "10001D10002D10003D10004D10005" = 29 chars  ✓
///   6 IDs de 5 dígitos → "10001D10002D10003D10004D10005D10006" = 35 chars ✗
library;

import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
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

// =============================================================================
// HELPERS DE DATOS
// =============================================================================

/// Ciclo por defecto de los pagos de estos tests. La validación de longitud de
/// referencia no depende del ciclo, pero la selección sí se agrupa por él.
const int _kCiclo = 2024;

/// Crea un [Alumno] con [cantidadPagos] pagos de IDs de 5 dígitos (10001, …).
Alumno _alumnoConPagos(int cantidadPagos) => Alumno(
      alumnoId: 1,
      familiaId: 1,
      familia: 'Familia Test',
      alumno: 'Test Alumno',
      apPaterno: 'Test',
      apMaterno: 'Test',
      nombre: 'Test',
      becaSep: 'No',
      becaArji: 'No',
      becaBach: 'No',
      becaSp: 'No',
      esBaja: false,
      grupoId: 1,
      grupo: '1ro A',
      urlPhoto: '',
      estadoDeCuenta: List.generate(
        cantidadPagos,
        (i) => EstadoDeCuenta(
          id: 10001 + i,
          cicloId: _kCiclo,
          nivelId: 1,
          descripcionCorta: 'Pago ${10001 + i}',
          total: 1000.0,
          totalFormatted: '\$1,000.00',
          fechaVencimiento: '2026-12-31',
          estadoPago: EstadoPago.pendiente,
          numPago: i + 1,
          numPagoActivo: true,
          aceptaPagosDiversos: false,
          estaDisponibleEnInternet: true,
          facturaPdf: '',
          facturaXml: '',
        ),
      ),
    );

/// Construye un [EstadosDeCuentaResponse] con el alumno indicado.
EstadosDeCuentaResponse _response(Alumno alumno) => EstadosDeCuentaResponse(
      alumnos: [alumno],
      cicloPredeterminadoId: '1',
      familiaId: '1',
      familia: 'Familia Test',
      success: true,
      message: '',
    );

// =============================================================================
// TESTS
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // Unit tests de CarritoState (sin BLoC)
  // ---------------------------------------------------------------------------
  group('CarritoState — referenciaValida', () {
    test(
      'es true cuando el carrito está vacío (referencia = "")',
      () {
        const state = CarritoState();
        expect(state.referenciaPago, isEmpty);
        expect(state.referenciaValida, isTrue);
      },
    );

    test(
      'es true cuando la referencia tiene ≤ ${AppConstants.maxLongitudReferencia} chars '
      '(5 IDs de 5 dígitos = 29 chars)',
      () {
        const state = CarritoState(
          pagosSeleccionados: {
            _kCiclo: {
              1: [10001, 10002, 10003, 10004, 10005],
            },
          },
        );
        // "10001D10002D10003D10004D10005" = 29 chars
        expect(state.referenciaPago.length, equals(29));
        expect(state.referenciaValida, isTrue);
      },
    );

    test(
      'es false cuando la referencia excede ${AppConstants.maxLongitudReferencia} chars '
      '(6 IDs de 5 dígitos = 35 chars)',
      () {
        const state = CarritoState(
          pagosSeleccionados: {
            _kCiclo: {
              1: [10001, 10002, 10003, 10004, 10005, 10006],
            },
          },
        );
        // "10001D10002D10003D10004D10005D10006" = 35 chars
        expect(state.referenciaPago.length, equals(35));
        expect(state.referenciaValida, isFalse);
      },
    );

    test(
      'es true para un único pago de IDs largos',
      () {
        const state = CarritoState(
          pagosSeleccionados: {
            _kCiclo: {1: [99999999]},
          },
        );
        // "99999999A0" = 10 chars ≤ 30
        expect(state.referenciaValida, isTrue);
      },
    );
  });

  group('CarritoState — longitudReferencia', () {
    test('es 0 para carrito vacío', () {
      const state = CarritoState();
      expect(state.longitudReferencia, equals(0));
    });

    test('calcula la longitud de la referencia correctamente', () {
      const state = CarritoState(
        pagosSeleccionados: {
          _kCiclo: {
            1: [100, 200, 300],
          },
        },
      );
      // "100D200D300" = 11 chars
      expect(state.longitudReferencia, equals('100D200D300'.length));
      expect(state.longitudReferencia, equals(11));
    });

    test('coincide con referenciaPago.length', () {
      const state = CarritoState(
        pagosSeleccionados: {
          _kCiclo: {
            1: [10001, 10002],
            2: [20001],
          },
        },
      );
      expect(state.longitudReferencia, equals(state.referenciaPago.length));
    });
  });

  // ---------------------------------------------------------------------------
  // BLoC tests de CarritoBloc
  // ---------------------------------------------------------------------------
  group('CarritoBloc — validación de referencia', () {
    late MockSharedPref mockSharedPref;
    late MockGetUserSessionUseCase mockGetUserSession;
    late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;

    setUp(() {
      mockSharedPref = MockSharedPref();
      mockGetUserSession = MockGetUserSessionUseCase();
      mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();

      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
      when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
    });

    CarritoBloc createBloc() => CarritoBloc(
          seleccionStorage: SeleccionPagosStorage(mockSharedPref),
          authUseCases: createMockAuthUseCases(getUserSession: mockGetUserSession),
          edoCtaUseCases: createMockEdoCtaUseCases(
            getEstadosDeCuenta: mockGetEstadosDeCuenta,
          ),
        );

    // -------------------------------------------------------------------------
    // CarritoPagarEvent — referencia inválida
    // -------------------------------------------------------------------------
    group('CarritoPagarEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'bloquea el pago y emite error cuando la referencia excede el límite '
        '(6 IDs de 5 dígitos = 35 chars > ${AppConstants.maxLongitudReferencia})',
        build: () => createBloc(),
        seed: () => const CarritoState(
          pagosSeleccionados: {
            _kCiclo: {
              1: [10001, 10002, 10003, 10004, 10005, 10006],
            },
          },
        ),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            AppStrings.carritoReferenciaExcede,
          ),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'no emite error de referencia cuando la referencia es válida '
        '(5 IDs de 5 dígitos = 29 chars ≤ ${AppConstants.maxLongitudReferencia})',
        build: () {
          when(() => mockGetUserSession.run())
              .thenAnswer((_) async => TestAuthResponse.valid);
          return createBloc();
        },
        seed: () => const CarritoState(
          pagosSeleccionados: {
            _kCiclo: {
              1: [10001, 10002, 10003, 10004, 10005],
            },
          },
        ),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        // Si la referencia es válida, avanza al procesamiento
        // (isProcesandoPago: true → luego pagoData)
        expect: () => [
          isA<CarritoState>().having(
            (s) => s.isProcesandoPago,
            'isProcesandoPago',
            true,
          ),
          isA<CarritoState>()
              .having((s) => s.isProcesandoPago, 'isProcesandoPago', false)
              .having((s) => s.pagoData, 'pagoData', isNotNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'el pago bloqueado no emite isProcesandoPago = true',
        build: () => createBloc(),
        seed: () => const CarritoState(
          pagosSeleccionados: {
            _kCiclo: {
              1: [10001, 10002, 10003, 10004, 10005, 10006],
            },
          },
        ),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        verify: (bloc) {
          // Nunca debe entrar en estado de procesando
          expect(bloc.state.isProcesandoPago, isFalse);
          expect(bloc.state.pagoData, isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // CarritoInitialEvent — referencia ya inválida al cargar del storage
    // -------------------------------------------------------------------------
    group('CarritoInitialEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'emite advertencia defensiva cuando la referencia cargada del storage '
        'excede el límite (6 IDs = 35 chars)',
        build: () {
          // El storage tiene 6 IDs de 5 dígitos → referencia de 35 chars
          when(() => mockSharedPref.readMap(any())).thenAnswer(
            (_) async => {
              '1': [10001, 10002, 10003, 10004, 10005, 10006],
            },
          );
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Success(_response(_alumnoConPagos(6))),
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const CarritoInitialEvent()),
        expect: () => [
          // 1. Cargando
          isA<CarritoState>().having((s) => s.isLoading, 'isLoading', true),
          // 2. Datos cargados — sin error aún
          isA<CarritoState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.alumnos, 'alumnos', isNotNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          // 3. Validación defensiva — emite el error
          isA<CarritoState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            AppStrings.carritoReferenciaExcede,
          ),
        ],
      );

      blocTest<CarritoBloc, CarritoState>(
        'no emite advertencia defensiva cuando la referencia cargada es válida '
        '(5 IDs = 29 chars)',
        build: () {
          when(() => mockSharedPref.readMap(any())).thenAnswer(
            (_) async => {
              '1': [10001, 10002, 10003, 10004, 10005],
            },
          );
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Success(_response(_alumnoConPagos(5))),
          );
          return createBloc();
        },
        act: (bloc) => bloc.add(const CarritoInitialEvent()),
        expect: () => [
          isA<CarritoState>().having((s) => s.isLoading, 'isLoading', true),
          isA<CarritoState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.alumnos, 'alumnos', isNotNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          // No debe haber un 3er estado con error
        ],
      );
    });
  });
}
