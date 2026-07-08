/// Tests unitarios para FacturaBloc.
///
/// Cubre la carga inicial y el refresh de facturas, con éxito y error,
/// usando el use case mockeado (`GetFacturasUseCase`).
library;

import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

/// Respuesta de facturas de prueba (lista vacía, suficiente para el flujo).
FacturaResponse get _facturaResponse => FacturaResponse(
      cicloPredeterminadoId: 2024,
      familiaId: 1,
      familia: 'Familia López García',
      facturas: [],
      success: true,
      message: 'ok',
    );

void main() {
  late MockGetFacturasUseCase mockGetFacturas;

  FacturaBloc buildBloc() =>
      FacturaBloc(createMockFacturaUseCases(getFacturas: mockGetFacturas));

  setUp(() {
    mockGetFacturas = MockGetFacturasUseCase();
  });

  test('estado inicial es FacturaState.initial()', () {
    final bloc = buildBloc();
    expect(bloc.state, FacturaState.initial());
    bloc.close();
  });

  group('FacturaInicialEvent', () {
    blocTest<FacturaBloc, FacturaState>(
      'emite [loading, datos] cuando la carga tiene éxito',
      build: buildBloc,
      setUp: () {
        when(() => mockGetFacturas.run())
            .thenAnswer((_) async => Success(_facturaResponse));
      },
      act: (bloc) => bloc.add(const FacturaInicialEvent()),
      expect: () => [
        isA<FacturaState>().having((s) => s.isLoading, 'isLoading', true),
        isA<FacturaState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.response, 'response', isNotNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<FacturaBloc, FacturaState>(
      'emite [loading, error] cuando la carga falla',
      build: buildBloc,
      setUp: () {
        when(() => mockGetFacturas.run())
            .thenAnswer((_) async => Error('Sin conexión'));
      },
      act: (bloc) => bloc.add(const FacturaInicialEvent()),
      expect: () => [
        isA<FacturaState>().having((s) => s.isLoading, 'isLoading', true),
        isA<FacturaState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage', 'Sin conexión'),
      ],
    );
  });

  group('FacturaRefreshEvent', () {
    blocTest<FacturaBloc, FacturaState>(
      'recarga las facturas correctamente',
      build: buildBloc,
      setUp: () {
        when(() => mockGetFacturas.run())
            .thenAnswer((_) async => Success(_facturaResponse));
      },
      act: (bloc) => bloc.add(const FacturaRefreshEvent()),
      expect: () => [
        isA<FacturaState>().having((s) => s.isLoading, 'isLoading', true),
        isA<FacturaState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.response, 'response', isNotNull),
      ],
    );
  });
}
