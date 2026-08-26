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

/// Crea un pago de prueba del emisor fiscal indicado.
EstadoDeCuenta _pago({
  required int id,
  required int cicloId,
  int emisorFiscalId = 1,
}) =>
    EstadoDeCuenta(
      id: id,
      cicloId: cicloId,
      nivelId: 1,
      emisorFiscalId: emisorFiscalId,
      descripcionCorta: 'Pago $id',
      total: 1000.0,
      totalFormatted: '\$1,000.00',
      fechaVencimiento: '2026-12-31',
      estadoPago: EstadoPago.pendiente,
      numPago: 1,
      numPagoActivo: true,
      aceptaPagosDiversos: false,
      estaDisponibleEnInternet: true,
      estaDisponibleEnLaAppMovil: true,
      facturaPdf: '',
      facturaXml: '',
    );

/// Alumno de prueba sin pagos. Se le cuelgan con `conEstadoDeCuenta`.
Alumno _alumnoBase(int alumnoId) => Alumno(
      alumnoId: alumnoId,
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
      estadoDeCuenta: const [],
    );

/// Crea un [Alumno] con [cantidadPagos] pagos de IDs de 5 dígitos (10001, …).
Alumno _alumnoConPagos(int cantidadPagos) => _alumnoBase(1).conEstadoDeCuenta(
      List.generate(
        cantidadPagos,
        (i) => _pago(id: 10001 + i, cicloId: _kCiclo),
      ),
    );

/// Construye un [CarritoState] con la selección indicada y los alumnos a los
/// que pertenecen esos pagos.
///
/// Desde que los pagos se reparten por emisor fiscal, el carrito necesita los
/// datos del pago para saber cuál es suyo: total y referencia ya no se pueden
/// calcular solo con el mapa de selección, porque ese mapa guarda junta la
/// selección de los dos emisores.
CarritoState _estadoCon(
  Map<int, Map<int, List<int>>> seleccion, {
  int emisorFiscalId = 1,
}) {
  final porAlumno = <int, List<EstadoDeCuenta>>{};
  seleccion.forEach((cicloId, mapaAlumnos) {
    mapaAlumnos.forEach((alumnoId, ids) {
      porAlumno.putIfAbsent(alumnoId, () => <EstadoDeCuenta>[]).addAll(
            ids.map((id) => _pago(
                  id: id,
                  cicloId: cicloId,
                  emisorFiscalId: emisorFiscalId,
                )),
          );
    });
  });

  return CarritoState(
    alumnos: porAlumno.entries
        .map((e) => _alumnoBase(e.key).conEstadoDeCuenta(e.value))
        .toList(),
    pagosSeleccionados: seleccion,
    emisorFiscalActivo: emisorFiscalId,
  );
}

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
        final state = _estadoCon(
          {
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
        final state = _estadoCon(
          {
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
        final state = _estadoCon(
          {
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
      final state = _estadoCon(
        {
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
      final state = _estadoCon(
        {
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
          seleccionStorage: SeleccionPagosStorage(mockSharedPref, claveSeleccion: 'seleccion_pagos_ef1'),
          authUseCases: createMockAuthUseCases(getUserSession: mockGetUserSession),
          edoCtaUseCases: createMockEdoCtaUseCases(
            getEstadosDeCuenta: mockGetEstadosDeCuenta,
          ),
          emisorFiscalId: 1,
        );

    // -------------------------------------------------------------------------
    // CarritoPagarEvent — referencia inválida
    // -------------------------------------------------------------------------
    group('CarritoPagarEvent', () {
      blocTest<CarritoBloc, CarritoState>(
        'bloquea el pago y emite error cuando la referencia excede el límite '
        '(6 IDs de 5 dígitos = 35 chars > ${AppConstants.maxLongitudReferencia})',
        build: () => createBloc(),
        seed: () => _estadoCon(
          {
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
        seed: () => _estadoCon(
          {
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
        seed: () => _estadoCon(
          {
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
          // El storage tiene 6 IDs de 5 dígitos → referencia de 35 chars.
          // En formato con ciclo, que es el que usa la app: el ciclo debe
          // coincidir con el de los pagos del alumno, porque desde que hay dos
          // emisores la referencia se arma recorriendo los pagos y no el mapa.
          when(() => mockSharedPref.readMap(any())).thenAnswer(
            (_) async => {
              '$_kCiclo': {
                '1': [10001, 10002, 10003, 10004, 10005, 10006],
              },
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
              '$_kCiclo': {
                '1': [10001, 10002, 10003, 10004, 10005],
              },
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
