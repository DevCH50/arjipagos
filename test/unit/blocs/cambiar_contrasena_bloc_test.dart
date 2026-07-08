/// Tests unitarios para CambiarContrasenaBloc.
///
/// Cubre la validación en tiempo real de los campos del formulario y el envío
/// (mismatch de contraseñas, éxito con logout, y error del servidor), usando
/// los use cases mockeados de autenticación.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockCambiarContrasenaUseCase mockCambiar;
  late MockLogoutUseCase mockLogout;

  CambiarContrasenaBloc buildBloc() => CambiarContrasenaBloc(
        createMockAuthUseCases(
          cambiarContrasena: mockCambiar,
          logout: mockLogout,
        ),
      );

  setUp(() {
    mockCambiar = MockCambiarContrasenaUseCase();
    mockLogout = MockLogoutUseCase();
  });

  group('validación de campos', () {
    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'PasswordNuevoChanged marca error cuando tiene menos de 6 caracteres',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PasswordNuevoChanged(passwordNuevo: BlocForItem(value: '123')),
      ),
      expect: () => [
        isA<CambiarContrasenaState>()
            .having((s) => s.passwordNuevo.error, 'error', 'Mínimo 6 caracteres'),
      ],
    );

    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'PasswordNuevoChanged sin error cuando es válida',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PasswordNuevoChanged(passwordNuevo: BlocForItem(value: 'segura123')),
      ),
      expect: () => [
        isA<CambiarContrasenaState>()
            .having((s) => s.passwordNuevo.error, 'error', isNull),
      ],
    );

    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'PasswordConfirmarChanged marca error cuando no coincide',
      build: buildBloc,
      seed: () => const CambiarContrasenaState(
        passwordNuevo: BlocForItem(value: 'segura123'),
      ),
      act: (bloc) => bloc.add(
        const PasswordConfirmarChanged(
            passwordConfirmar: BlocForItem(value: 'otra456')),
      ),
      expect: () => [
        isA<CambiarContrasenaState>().having(
          (s) => s.passwordConfirmar.error,
          'error',
          AppStrings.cambiarContrasenaNoCoinciden,
        ),
      ],
    );
  });

  group('CambiarContrasenaSubmitted', () {
    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'no llama al servidor si las contraseñas no coinciden',
      build: buildBloc,
      seed: () => const CambiarContrasenaState(
        passwordActual: BlocForItem(value: 'actual1'),
        passwordNuevo: BlocForItem(value: 'segura123'),
        passwordConfirmar: BlocForItem(value: 'distinta9'),
      ),
      act: (bloc) => bloc.add(const CambiarContrasenaSubmitted()),
      expect: () => [
        isA<CambiarContrasenaState>().having(
          (s) => s.passwordConfirmar.error,
          'error',
          AppStrings.cambiarContrasenaNoCoinciden,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockCambiar.run(any(), any()));
      },
    );

    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'emite [Loading, Success] y cierra sesión cuando el cambio es exitoso',
      build: buildBloc,
      seed: () => const CambiarContrasenaState(
        passwordActual: BlocForItem(value: 'actual1'),
        passwordNuevo: BlocForItem(value: 'segura123'),
        passwordConfirmar: BlocForItem(value: 'segura123'),
      ),
      setUp: () {
        when(() => mockCambiar.run(any(), any()))
            .thenAnswer((_) async => Success('Contraseña actualizada'));
        when(() => mockLogout.run()).thenAnswer((_) async => true);
      },
      act: (bloc) => bloc.add(const CambiarContrasenaSubmitted()),
      expect: () => [
        isA<CambiarContrasenaState>().having((s) => s.response, 'response', isA<Loading>()),
        isA<CambiarContrasenaState>().having((s) => s.response, 'response', isA<Success>()),
      ],
      verify: (_) {
        verify(() => mockLogout.run()).called(1);
      },
    );

    blocTest<CambiarContrasenaBloc, CambiarContrasenaState>(
      'emite [Loading, Error] cuando el servidor falla y NO cierra sesión',
      build: buildBloc,
      seed: () => const CambiarContrasenaState(
        passwordActual: BlocForItem(value: 'actual1'),
        passwordNuevo: BlocForItem(value: 'segura123'),
        passwordConfirmar: BlocForItem(value: 'segura123'),
      ),
      setUp: () {
        when(() => mockCambiar.run(any(), any()))
            .thenAnswer((_) async => Error('La contraseña actual no coincide'));
      },
      act: (bloc) => bloc.add(const CambiarContrasenaSubmitted()),
      expect: () => [
        isA<CambiarContrasenaState>().having((s) => s.response, 'response', isA<Loading>()),
        isA<CambiarContrasenaState>().having((s) => s.response, 'response', isA<Error>()),
      ],
      verify: (_) {
        verifyNever(() => mockLogout.run());
      },
    );
  });
}
