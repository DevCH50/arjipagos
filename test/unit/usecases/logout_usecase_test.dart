/// Tests unitarios para LogoutUseCase.
library;

import 'package:arjipagos/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late LogoutUseCase logoutUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    logoutUseCase = LogoutUseCase(mockAuthRepository);
  });

  group('LogoutUseCase', () {
    test('debe retornar true cuando el logout es exitoso', () async {
      // Arrange
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => true);

      // Act
      final result = await logoutUseCase.run();

      // Assert
      expect(result, isTrue);
      verify(() => mockAuthRepository.logout()).called(1);
    });

    test('debe retornar false cuando el logout falla', () async {
      // Arrange
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => false);

      // Act
      final result = await logoutUseCase.run();

      // Assert
      expect(result, isFalse);
      verify(() => mockAuthRepository.logout()).called(1);
    });

    test('debe llamar al repositorio exactamente una vez', () async {
      // Arrange
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => true);

      // Act
      await logoutUseCase.run();

      // Assert
      verify(() => mockAuthRepository.logout()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
