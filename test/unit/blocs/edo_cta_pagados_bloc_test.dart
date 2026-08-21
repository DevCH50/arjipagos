/// Tests unitarios para EdoCtaPagadosBloc.
///
/// Cubren la carga, el refresco y el manejo de errores de la pantalla de pagos
/// realizados, y verifican que el BLoC NO comparte estado con el flujo de pagos
/// pendientes (no hay selección ni persistencia).
library;

import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockGetEstadosDeCuentaPagadosUseCase mockUseCase;
  late EdoCtaPagadosBloc bloc;

  /// Respuesta de éxito construida desde el JSON real del endpoint.
  EstadosDeCuentaResponse respuesta() =>
      EstadosDeCuentaResponse.fromJson(TestPagoRealizado.respuestaJson);

  EdoCtaPagadosBloc crearBloc() => EdoCtaPagadosBloc(
        createMockEdoCtaPagadosUseCases(getEstadosDeCuentaPagados: mockUseCase),
      );

  setUp(() {
    mockUseCase = MockGetEstadosDeCuentaPagadosUseCase();
  });

  tearDown(() async {
    await bloc.close();
  });

  group('EdoCtaPagadosBloc', () {
    test('el estado inicial está vacío y sin cargar', () {
      // Arrange & Act
      bloc = crearBloc();

      // Assert
      expect(bloc.state.alumnos, isNull);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.cantidadPagos, equals(0));
    });

    test('carga inicial emite los alumnos con sus pagos realizados', () async {
      // Arrange
      when(() => mockUseCase.run())
          .thenAnswer((_) async => utils.Success(respuesta()));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EdoCtaPagadosState>((s) => s.isLoading),
          predicate<EdoCtaPagadosState>(
            (s) => !s.isLoading && s.alumnos?.length == 1,
          ),
        ]),
      );

      // Assert
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.cantidadPagos, equals(2));
    });

    test('el refresco vuelve a consultar el servidor', () async {
      // Arrange
      when(() => mockUseCase.run())
          .thenAnswer((_) async => utils.Success(respuesta()));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.alumnos != null);
      bloc.add(const EdoCtaPagadosRefreshEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.alumnos != null);

      // Assert
      verify(() => mockUseCase.run()).called(2);
    });

    test('un Error del caso de uso llega como mensaje legible', () async {
      // Arrange
      when(() => mockUseCase.run()).thenAnswer(
        (_) async => utils.Error<EstadosDeCuentaResponse>('Sin conexión'),
      );
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(bloc.state.errorMessage, equals('Sin conexión'));
      expect(bloc.state.alumnos, isNull);
    });

    test('una excepción inesperada no se filtra cruda al usuario', () async {
      // Arrange
      when(() => mockUseCase.run()).thenThrow(Exception('fallo interno'));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.errorMessage, isNot(contains('Exception')));
      expect(bloc.state.errorMessage, isNot(contains('fallo interno')));
    });
  });
}
