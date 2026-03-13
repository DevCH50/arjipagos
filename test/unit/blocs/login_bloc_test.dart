/// Tests unitarios para LoginBloc.
library;

import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  // Registrar fallback values para mocktail
  setUpAll(() {
    registerFallbackValue(TestAuthResponse.valid);
  });

  late LoginBloc loginBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockSaveUserSessionUseCase mockSaveUserSessionUseCase;
  late MockGetUserSessionUseCase mockGetUserSessionUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late AuthUseCases authUseCases;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockSaveUserSessionUseCase = MockSaveUserSessionUseCase();
    mockGetUserSessionUseCase = MockGetUserSessionUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockRegisterUseCase = MockRegisterUseCase();

    authUseCases = AuthUseCases(
      login: mockLoginUseCase,
      saveUserSession: mockSaveUserSessionUseCase,
      getUserSession: mockGetUserSessionUseCase,
      logout: mockLogoutUseCase,
      register: mockRegisterUseCase,
    );

    loginBloc = LoginBloc(authUseCases);
  });

  tearDown(() {
    loginBloc.close();
  });

  group('LoginBloc', () {
    test('estado inicial debe tener errores de validación', () {
      // Assert
      expect(loginBloc.state.email.error, equals('Ingresa el Username'));
      expect(loginBloc.state.password.error, equals('Ingresa la Contraseña'));
      expect(loginBloc.state.response, isNull);
    });

    group('EmailChanged', () {
      blocTest<LoginBloc, LoginState>(
        'debe actualizar el email y limpiar error cuando no está vacío',
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const EmailChanged(email: BlocForItem(value: 'usuario@test.com')),
        ),
        expect: () => [
          isA<LoginState>()
              .having((s) => s.email.value, 'email', 'usuario@test.com')
              .having((s) => s.email.error, 'error', isNull),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'debe mostrar error cuando el email está vacío',
        build: () => loginBloc,
        act: (bloc) =>
            bloc.add(const EmailChanged(email: BlocForItem(value: ''))),
        expect: () => [
          isA<LoginState>()
              .having((s) => s.email.value, 'email', '')
              .having(
                (s) => s.email.error,
                'error',
                'Escribe el Nombre de Usuario',
              ),
        ],
      );
    });

    group('PasswordChanged', () {
      blocTest<LoginBloc, LoginState>(
        'debe actualizar el password sin error cuando tiene 6+ caracteres',
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const PasswordChanged(password: BlocForItem(value: 'password123')),
        ),
        expect: () => [
          isA<LoginState>()
              .having((s) => s.password.value, 'password', 'password123')
              .having((s) => s.password.error, 'error', isNull),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'debe mostrar error cuando el password tiene menos de 6 caracteres',
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const PasswordChanged(password: BlocForItem(value: '12345')),
        ),
        expect: () => [
          isA<LoginState>()
              .having((s) => s.password.value, 'password', '12345')
              .having((s) => s.password.error, 'error', 'Mínimo 6 caracteres'),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'no debe mostrar error cuando el password está vacío',
        build: () => loginBloc,
        act: (bloc) =>
            bloc.add(const PasswordChanged(password: BlocForItem(value: ''))),
        expect: () => [
          isA<LoginState>()
              .having((s) => s.password.value, 'password', '')
              .having((s) => s.password.error, 'error', isNull),
        ],
      );
    });

    group('LoginSubmitted', () {
      blocTest<LoginBloc, LoginState>(
        'debe emitir Loading y luego Success cuando el login es exitoso',
        setUp: () {
          when(
            () => mockLoginUseCase.run(any(), any()),
          ).thenAnswer((_) async => Success(TestAuthResponse.valid));
        },
        build: () => loginBloc,
        seed: () => const LoginState(
          email: BlocForItem(value: 'usuario'),
          password: BlocForItem(value: 'password123'),
        ),
        act: (bloc) => bloc.add(const LoginSubmitted()),
        expect: () => [
          isA<LoginState>().having(
            (s) => s.response,
            'response',
            isA<Loading>(),
          ),
          isA<LoginState>().having(
            (s) => s.response,
            'response',
            isA<Success>(),
          ),
        ],
        verify: (_) {
          verify(
            () => mockLoginUseCase.run('usuario', 'password123'),
          ).called(1);
        },
      );

      blocTest<LoginBloc, LoginState>(
        'debe emitir Loading y luego Error cuando el login falla',
        setUp: () {
          when(
            () => mockLoginUseCase.run(any(), any()),
          ).thenAnswer((_) async => Error('Credenciales incorrectas'));
        },
        build: () => loginBloc,
        seed: () => const LoginState(
          email: BlocForItem(value: 'usuario'),
          password: BlocForItem(value: 'password123'),
        ),
        act: (bloc) => bloc.add(const LoginSubmitted()),
        expect: () => [
          isA<LoginState>().having(
            (s) => s.response,
            'response',
            isA<Loading>(),
          ),
          isA<LoginState>().having((s) => s.response, 'response', isA<Error>()),
        ],
      );
    });

    group('CheckSession', () {
      blocTest<LoginBloc, LoginState>(
        'debe emitir Success cuando existe sesión guardada',
        setUp: () {
          when(
            () => mockGetUserSessionUseCase.run(),
          ).thenAnswer((_) async => TestAuthResponse.valid);
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(const CheckSession()),
        expect: () => [
          isA<LoginState>().having(
            (s) => s.response,
            'response',
            isA<Success>(),
          ),
        ],
        verify: (_) {
          verify(() => mockGetUserSessionUseCase.run()).called(1);
        },
      );

      blocTest<LoginBloc, LoginState>(
        'debe emitir null cuando no existe sesión guardada',
        setUp: () {
          when(
            () => mockGetUserSessionUseCase.run(),
          ).thenAnswer((_) async => null);
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(const CheckSession()),
        expect: () => [
          isA<LoginState>().having((s) => s.response, 'response', isNull),
        ],
      );
    });

    group('LoginSaveUserSession', () {
      blocTest<LoginBloc, LoginState>(
        'debe llamar a saveUserSession con el AuthResponse correcto',
        setUp: () {
          when(
            () => mockSaveUserSessionUseCase.run(any()),
          ).thenAnswer((_) async {});
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          LoginSaveUserSession(authResponse: TestAuthResponse.valid),
        ),
        verify: (_) {
          verify(() => mockSaveUserSessionUseCase.run(any())).called(1);
        },
      );
    });
  });
}
