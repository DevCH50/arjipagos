/// Tests unitarios para RegisterBloc.
///
/// Cubre la validación en tiempo real de los campos (nombre, celular, email,
/// confirmación) y el envío del formulario (inválido → Error sin llamar al
/// servidor; válido → Loading + resultado), usando el use case mockeado.
library;

import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

/// Estado con todos los campos válidos (isFormValid == true).
RegisterState get _estadoValido => const RegisterState(
      nombre: BlocForItem(value: 'Juan'),
      apPaterno: BlocForItem(value: 'Pérez'),
      apMaterno: BlocForItem(value: 'García'),
      celular: BlocForItem(value: '5551234567'),
      email: BlocForItem(value: 'juan@ejemplo.com'),
      password: BlocForItem(value: 'secret123'),
      confirmPassword: BlocForItem(value: 'secret123'),
    );

void main() {
  late MockRegisterUseCase mockRegister;

  RegisterBloc buildBloc() =>
      RegisterBloc(createMockAuthUseCases(register: mockRegister));

  setUp(() {
    mockRegister = MockRegisterUseCase();
  });

  test('estado inicial es RegisterState() con formulario inválido', () {
    final bloc = buildBloc();
    expect(bloc.state.isFormValid, false);
    bloc.close();
  });

  group('validación de campos', () {
    blocTest<RegisterBloc, RegisterState>(
      'NombreChanged vacío marca error',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const NombreChanged(nombre: BlocForItem(value: ''))),
      expect: () => [
        isA<RegisterState>()
            .having((s) => s.nombre.error, 'error', 'Ingresa tu nombre'),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'CelularChanged con formato inválido marca error',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const CelularChanged(celular: BlocForItem(value: '123'))),
      expect: () => [
        isA<RegisterState>().having(
            (s) => s.celular.error, 'error', 'El celular debe tener 10 dígitos'),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'EmailRegisterChanged con formato inválido marca error',
      build: buildBloc,
      act: (bloc) => bloc
          .add(const EmailRegisterChanged(email: BlocForItem(value: 'no-mail'))),
      expect: () => [
        isA<RegisterState>()
            .having((s) => s.email.error, 'error', 'Ingresa un email válido'),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'ConfirmPasswordChanged que no coincide marca error',
      build: buildBloc,
      seed: () => const RegisterState(password: BlocForItem(value: 'secret123')),
      act: (bloc) => bloc.add(const ConfirmPasswordChanged(
          confirmPassword: BlocForItem(value: 'otra456'))),
      expect: () => [
        isA<RegisterState>().having((s) => s.confirmPassword.error, 'error',
            'Las contraseñas no coinciden'),
      ],
    );
  });

  group('RegisterSubmitted', () {
    blocTest<RegisterBloc, RegisterState>(
      'emite Error y NO llama al servidor si el formulario es inválido',
      build: buildBloc,
      act: (bloc) => bloc.add(const RegisterSubmitted()),
      expect: () => [
        isA<RegisterState>().having((s) => s.response, 'response', isA<Error>()),
      ],
      verify: (_) {
        verifyNever(() => mockRegister.run(
              nombre: any(named: 'nombre'),
              apPaterno: any(named: 'apPaterno'),
              apMaterno: any(named: 'apMaterno'),
              celular: any(named: 'celular'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [Loading, Success] cuando el formulario es válido',
      build: buildBloc,
      seed: () => _estadoValido,
      setUp: () {
        when(() => mockRegister.run(
              nombre: any(named: 'nombre'),
              apPaterno: any(named: 'apPaterno'),
              apMaterno: any(named: 'apMaterno'),
              celular: any(named: 'celular'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Success('Registro exitoso'));
      },
      act: (bloc) => bloc.add(const RegisterSubmitted()),
      expect: () => [
        isA<RegisterState>()
            .having((s) => s.response, 'response', isA<Loading>()),
        isA<RegisterState>()
            .having((s) => s.response, 'response', isA<Success>()),
      ],
    );
  });
}
