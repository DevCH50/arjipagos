/// Tests unitarios para LoginUseCase.
library;

import 'package:arjipagos/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockAuthRepository);
  });

  group('LoginUseCase', () {
    const username = 'juanperez';
    const password = 'password123';

    test('debe retornar Success con AuthResponse cuando el login es exitoso', () async {
      // Arrange
      when(() => mockAuthRepository.login(username, password))
          .thenAnswer((_) async => Success(TestAuthResponse.valid));

      // Act
      final result = await loginUseCase.run(username, password);

      // Assert
      expect(result, isA<Success>());
      verify(() => mockAuthRepository.login(username, password)).called(1);
    });

    test('debe retornar Error cuando las credenciales son incorrectas', () async {
      // Arrange
      const errorMessage = 'Credenciales incorrectas';
      when(() => mockAuthRepository.login(username, password))
          .thenAnswer((_) async => Error(errorMessage));

      // Act
      final result = await loginUseCase.run(username, password);

      // Assert
      expect(result, isA<Error>());
      expect((result as Error).msg, equals(errorMessage));
      verify(() => mockAuthRepository.login(username, password)).called(1);
    });

    test('debe retornar Error cuando hay error de conexión', () async {
      // Arrange
      const errorMessage = 'Error de conexión';
      when(() => mockAuthRepository.login(username, password))
          .thenAnswer((_) async => Error(errorMessage));

      // Act
      final result = await loginUseCase.run(username, password);

      // Assert
      expect(result, isA<Error>());
      expect((result as Error).msg, equals(errorMessage));
    });

    test('debe llamar al repositorio con los parámetros correctos', () async {
      // Arrange
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => Success(TestAuthResponse.valid));

      // Act
      await loginUseCase.run('usuario1', 'clave123');

      // Assert
      verify(() => mockAuthRepository.login('usuario1', 'clave123')).called(1);
    });

    test('debe manejar username vacío', () async {
      // Arrange
      when(() => mockAuthRepository.login('', password))
          .thenAnswer((_) async => Error('Username requerido'));

      // Act
      final result = await loginUseCase.run('', password);

      // Assert
      expect(result, isA<Error>());
    });

    test('debe manejar password vacío', () async {
      // Arrange
      when(() => mockAuthRepository.login(username, ''))
          .thenAnswer((_) async => Error('Password requerido'));

      // Act
      final result = await loginUseCase.run(username, '');

      // Assert
      expect(result, isA<Error>());
    });
  });
}
