/// Tests para la validación de longitud de referencia de pago en EdoCtaListBloc.
///
/// Verifica que al intentar seleccionar un pago cuya inclusión haría que la
/// referencia supere los 30 caracteres (límite de Adquira México), el BLoC:
///   - Emite un errorMessage con el texto correcto.
///   - Limpia el errorMessage en el siguiente ciclo.
///   - No añade el pago a [pagosSeleccionados].
///
/// Los tests usan IDs de 5 dígitos (10001, 10002, …) para alcanzar el límite
/// con pocas selecciones:
///   5 IDs → "10001D10002D10003D10004D10005" = 29 chars  ✓ (permitido)
///   6 IDs → "10001D10002D10003D10004D10005D10006" = 35 chars ✗ (bloqueado)
library;

import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

// =============================================================================
// HELPERS DE DATOS
// =============================================================================

/// Crea un [EstadoDeCuenta] mínimo con el [id] indicado, sin restricción de
/// orden ([aceptaPagosDiversos] = false) para que los tests se enfoquen
/// exclusivamente en la validación de longitud de referencia.
EstadoDeCuenta _pago({required int id}) => EstadoDeCuenta(
      id: id,
      descripcionCorta: 'Pago $id',
      total: 1000.0,
      totalFormatted: '\$1,000.00',
      fechaVencimiento: '2026-12-31',
      estadoPago: EstadoPago.pendiente,
      numPago: 1,
      numPagoActivo: true,
      aceptaPagosDiversos: false,
      estaDisponibleEnInternet: true,
      facturaPdf: '',
      facturaXml: '',
    );

/// Crea un [Alumno] con [cantidadPagos] pagos de IDs de 5 dígitos consecutivos
/// a partir de 10001 (10001, 10002, …).
Alumno _alumno({required int alumnoId, required int cantidadPagos}) => Alumno(
      alumnoId: alumnoId,
      alumno: 'Alumno $alumnoId',
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
      estadoDeCuenta: List.generate(cantidadPagos, (i) => _pago(id: 10001 + i)),
    );

/// Igual que [_alumno] pero usa IDs que inician en 20001 (para diferenciar
/// un segundo alumno en tests multi-alumno).
Alumno _alumnoB({required int alumnoId, required int cantidadPagos}) => Alumno(
      alumnoId: alumnoId,
      alumno: 'Alumno B $alumnoId',
      apPaterno: 'Test',
      apMaterno: 'Test',
      nombre: 'Test',
      becaSep: 'No',
      becaArji: 'No',
      becaBach: 'No',
      becaSp: 'No',
      esBaja: false,
      grupoId: 1,
      grupo: '1ro B',
      urlPhoto: '',
      estadoDeCuenta: List.generate(cantidadPagos, (i) => _pago(id: 20001 + i)),
    );

// =============================================================================
// TESTS
// =============================================================================

void main() {
  late MockSharedPref mockSharedPref;

  setUp(() {
    mockSharedPref = MockSharedPref();
    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  EdoCtaListBloc createBloc() => EdoCtaListBloc(
        createMockEdoCtaUseCases(),
        mockSharedPref,
      );

  group(
    'EdoCtaListBloc — validación de longitud de referencia '
    '(límite = ${AppConstants.maxLongitudReferencia} chars)',
    () {
      // Alumno de prueba con 6 pagos de IDs de 5 dígitos
      const alumnoId = 10;
      final alumno = _alumno(alumnoId: alumnoId, cantidadPagos: 6);

      // ---------------------------------------------------------------------------
      // Caso base: primer pago siempre permitido
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'permite seleccionar el primer pago (referencia = 5 chars, dentro del límite)',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          alumnos: [alumno],
          pagosSeleccionados: const {},
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: alumnoId,
          pagoId: 10001,
        )),
        expect: () => [
          isA<EdoCtaListState>()
              .having((s) => s.errorMessage, 'errorMessage', isNull)
              .having(
                (s) => s.pagosSeleccionados[alumnoId],
                'pago añadido',
                [10001],
              ),
        ],
      );

      // ---------------------------------------------------------------------------
      // 5to pago: referencia resultante = 29 chars → permitido
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'permite seleccionar el 5to pago '
        '(referencia resultante = 29 chars ≤ ${AppConstants.maxLongitudReferencia})',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          alumnos: [alumno],
          pagosSeleccionados: const {
            alumnoId: [10001, 10002, 10003, 10004],
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: alumnoId,
          pagoId: 10005,
        )),
        expect: () => [
          isA<EdoCtaListState>()
              .having((s) => s.errorMessage, 'errorMessage', isNull)
              .having(
                (s) => s.pagosSeleccionados[alumnoId]?.length,
                'cantidad de pagos',
                5,
              ),
        ],
      );

      // ---------------------------------------------------------------------------
      // 6to pago: referencia resultante = 35 chars → bloqueado
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'bloquea el 6to pago '
        '(referencia resultante = 35 chars > ${AppConstants.maxLongitudReferencia})',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          alumnos: [alumno],
          pagosSeleccionados: const {
            alumnoId: [10001, 10002, 10003, 10004, 10005],
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: alumnoId,
          pagoId: 10006,
        )),
        expect: () => [
          // 1er emit: errorMessage con el texto de AppStrings
          isA<EdoCtaListState>()
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                AppStrings.edoCtaReferenciaLimiteAlcanzado,
              )
              // El pago NO se añadió — sigue siendo 5
              .having(
                (s) => s.pagosSeleccionados[alumnoId]?.length,
                'pagos sin cambio',
                5,
              ),
          // 2do emit: errorMessage se limpia
          isA<EdoCtaListState>()
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      // ---------------------------------------------------------------------------
      // El pago bloqueado no modifica el mapa pagosSeleccionados
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'pagosSeleccionados no cambia cuando el pago es bloqueado por el límite',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          alumnos: [alumno],
          pagosSeleccionados: const {
            alumnoId: [10001, 10002, 10003, 10004, 10005],
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: alumnoId,
          pagoId: 10006,
        )),
        verify: (bloc) {
          final estadoFinal = bloc.state;
          expect(
            estadoFinal.pagosSeleccionados[alumnoId],
            equals([10001, 10002, 10003, 10004, 10005]),
          );
          expect(estadoFinal.pagosSeleccionados[alumnoId]?.length, equals(5));
        },
      );

      // ---------------------------------------------------------------------------
      // Multi-alumno: la validación acumula IDs de TODOS los alumnos
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'bloquea cuando la referencia combinada de múltiples alumnos excedería el límite',
        // Alumno A: IDs 10001, 10002, 10003  →  parte de referencia: "10001D10002D10003"
        // Alumno B: IDs 20001, 20002         →  parte de referencia: "D20001D20002"
        // Referencia actual: "10001D10002D10003D20001D20002" = 29 chars  ✓
        // Añadir 10004 a A  → "10001D10002D10003D10004D20001D20002" = 35 chars  ✗
        build: () => createBloc(),
        seed: () {
          final alumnoA = _alumno(alumnoId: 1, cantidadPagos: 5);
          final alumnoB = _alumnoB(alumnoId: 2, cantidadPagos: 3);
          return EdoCtaListState(
            alumnos: [alumnoA, alumnoB],
            pagosSeleccionados: const {
              1: [10001, 10002, 10003],
              2: [20001, 20002],
            },
          );
        },
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: 1,
          pagoId: 10004,
        )),
        expect: () => [
          isA<EdoCtaListState>()
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                AppStrings.edoCtaReferenciaLimiteAlcanzado,
              ),
          isA<EdoCtaListState>()
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      // ---------------------------------------------------------------------------
      // Desmarcar siempre está permitido (independiente del límite)
      // ---------------------------------------------------------------------------
      blocTest<EdoCtaListBloc, EdoCtaListState>(
        'siempre permite deseleccionar un pago aunque la referencia ya esté en el límite',
        build: () => createBloc(),
        seed: () => EdoCtaListState(
          alumnos: [alumno],
          pagosSeleccionados: const {
            alumnoId: [10001, 10002, 10003, 10004, 10005],
          },
        ),
        act: (bloc) => bloc.add(const EdoCtaTogglePagoEvent(
          alumnoId: alumnoId,
          pagoId: 10005, // deseleccionar el 5to
        )),
        expect: () => [
          isA<EdoCtaListState>()
              .having((s) => s.errorMessage, 'errorMessage', isNull)
              .having(
                (s) => s.pagosSeleccionados[alumnoId]?.length,
                'baja a 4 pagos',
                4,
              ),
        ],
      );
    },
  );
}
