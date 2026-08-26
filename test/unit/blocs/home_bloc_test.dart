/// Tests unitarios para HomeBloc.
library;

import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late HomeBloc homeBloc;
  late MockGetAlumnosUseCase mockGetAlumnosUseCase;
  late HomeUseCases homeUseCases;

  setUp(() {
    mockGetAlumnosUseCase = MockGetAlumnosUseCase();
    homeUseCases = HomeUseCases(getAlumnos: mockGetAlumnosUseCase);

    homeBloc = HomeBloc(homeUseCases);
  });

  tearDown(() {
    homeBloc.close();
  });

  group('HomeBloc', () {
    test('estado inicial debe estar vacío y sin carga', () {
      // Assert
      expect(homeBloc.state.alumnos, isNull);
      expect(homeBloc.state.alumnosResponse, isNull);
      expect(homeBloc.state.isLoading, isFalse);
      expect(homeBloc.state.errorMessage, isNull);
    });

    group('GetHomesList', () {
      blocTest<HomeBloc, HomeState>(
        'debe emitir loading y luego lista de alumnos cuando es exitoso',
        setUp: () {
          when(
            () => mockGetAlumnosUseCase.run(),
          ).thenAnswer((_) async => Success(TestAlumnoResponse.valid));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const GetHomesList()),
        expect: () => [
          // Estado de carga
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isTrue)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          // Estado de éxito
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.alumnos, 'alumnos', hasLength(2))
              .having((s) => s.alumnosResponse, 'alumnosResponse', isNotNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
        verify: (_) {
          verify(() => mockGetAlumnosUseCase.run()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'debe emitir loading y luego lista vacía cuando no hay alumnos',
        setUp: () {
          when(
            () => mockGetAlumnosUseCase.run(),
          ).thenAnswer((_) async => Success(TestAlumnoResponse.empty));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const GetHomesList()),
        expect: () => [
          isA<HomeState>().having((s) => s.isLoading, 'isLoading', isTrue),
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.alumnos, 'alumnos', isEmpty),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'debe emitir loading y luego error cuando falla la petición',
        setUp: () {
          when(
            () => mockGetAlumnosUseCase.run(),
          ).thenAnswer((_) async => Error('Error de conexión'));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const GetHomesList()),
        expect: () => [
          isA<HomeState>().having((s) => s.isLoading, 'isLoading', isTrue),
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'Error de conexión',
              ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'debe emitir error cuando no hay sesión activa',
        setUp: () {
          when(
            () => mockGetAlumnosUseCase.run(),
          ).thenAnswer((_) async => Error('No hay sesión activa'));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const GetHomesList()),
        expect: () => [
          isA<HomeState>().having((s) => s.isLoading, 'isLoading', isTrue),
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'No hay sesión activa',
              ),
        ],
      );
    });

    group('RefreshHomesList', () {
      blocTest<HomeBloc, HomeState>(
        'debe recargar la lista de alumnos',
        setUp: () {
          when(
            () => mockGetAlumnosUseCase.run(),
          ).thenAnswer((_) async => Success(TestAlumnoResponse.valid));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const RefreshHomesList()),
        expect: () => [
          isA<HomeState>().having((s) => s.isLoading, 'isLoading', isTrue),
          isA<HomeState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.alumnos, 'alumnos', hasLength(2)),
        ],
        verify: (_) {
          verify(() => mockGetAlumnosUseCase.run()).called(1);
        },
      );
    });

    group('HomeLimpiarSesionEvent', () {
      blocTest<HomeBloc, HomeState>(
        'devuelve el estado inicial, sin los alumnos del usuario anterior',
        build: () => homeBloc,
        seed: () => HomeState.initial().copyWith(
          errorMessage: 'Error del usuario anterior',
        ),
        act: (bloc) => bloc.add(const HomeLimpiarSesionEvent()),
        expect: () => [HomeState.initial()],
      );
    });

    group('HomeState', () {
      test('copyWith debe crear una copia correcta del estado', () {
        // Arrange
        final originalState = HomeState.initial();

        // Act
        final newState = originalState.copyWith(
          isLoading: true,
          errorMessage: 'Error',
        );

        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.errorMessage, equals('Error'));
        expect(newState.alumnos, isNull);
      });

      test('initial debe crear un estado limpio', () {
        // Arrange & Act
        final state = HomeState.initial();

        // Assert
        expect(state.alumnos, isNull);
        expect(state.alumnosResponse, isNull);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      });

      test('copyWith debe limpiar errorMessage cuando se pasa null', () {
        // Arrange
        const stateConError = HomeState(
          isLoading: false,
          errorMessage: 'Error previo',
        );

        // Act
        final stateNuevo = stateConError.copyWith(
          isLoading: true,
          errorMessage: null,
        );

        // Assert
        expect(stateNuevo.errorMessage, isNull);
      });
    });
  });
}
