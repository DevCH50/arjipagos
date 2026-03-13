/// Tests unitarios para GetUserSessionUseCase.
library;

import 'package:arjipagos/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late GetUserSessionUseCase getUserSessionUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    getUserSessionUseCase = GetUserSessionUseCase(mockAuthRepository);
  });

  group('GetUserSessionUseCase', () {
    test('debe retornar AuthResponse cuando existe sesión guardada', () async {
      // Arrange
      when(() => mockAuthRepository.getUserSession())
          .thenAnswer((_) async => TestAuthResponse.valid);

      // Act
      final result = await getUserSessionUseCase.run();

      // Assert
      expect(result, isNotNull);
      expect(result!.user.username, equals('juanperez'));
      expect(result.accessToken, isNotEmpty);
      verify(() => mockAuthRepository.getUserSession()).called(1);
    });

    test('debe retornar null cuando no existe sesión guardada', () async {
      // Arrange
      when(() => mockAuthRepository.getUserSession())
          .thenAnswer((_) async => null);

      // Act
      final result = await getUserSessionUseCase.run();

      // Assert
      expect(result, isNull);
      verify(() => mockAuthRepository.getUserSession()).called(1);
    });

    test('debe llamar al repositorio exactamente una vez', () async {
      // Arrange
      when(() => mockAuthRepository.getUserSession())
          .thenAnswer((_) async => TestAuthResponse.valid);

      // Act
      await getUserSessionUseCase.run();

      // Assert
      verify(() => mockAuthRepository.getUserSession()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
