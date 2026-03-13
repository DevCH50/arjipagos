/// Tests unitarios para GetAlumnosUseCase.
library;

import 'package:arjipagos/src/domain/useCases/alumnos/GetAlumnosUseCase.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late GetAlumnosUseCase getAlumnosUseCase;
  late MockHomeRepository mockHomeRepository;

  setUp(() {
    mockHomeRepository = MockHomeRepository();
    getAlumnosUseCase = GetAlumnosUseCase(mockHomeRepository);
  });

  group('GetAlumnosUseCase', () {
    test('debe retornar Success con AlumnoResponse cuando hay alumnos', () async {
      // Arrange
      when(() => mockHomeRepository.getAlumnos())
          .thenAnswer((_) async => Success(TestAlumnoResponse.valid));

      // Act
      final result = await getAlumnosUseCase.run();

      // Assert
      expect(result, isA<Success>());
      final data = (result as Success).data;
      expect(data.alumnos, hasLength(2));
      verify(() => mockHomeRepository.getAlumnos()).called(1);
    });

    test('debe retornar Success con lista vacía cuando no hay alumnos', () async {
      // Arrange
      when(() => mockHomeRepository.getAlumnos())
          .thenAnswer((_) async => Success(TestAlumnoResponse.empty));

      // Act
      final result = await getAlumnosUseCase.run();

      // Assert
      expect(result, isA<Success>());
      final data = (result as Success).data;
      expect(data.alumnos, isEmpty);
    });

    test('debe retornar Error cuando no hay sesión activa', () async {
      // Arrange
      const errorMessage = 'No hay sesión activa';
      when(() => mockHomeRepository.getAlumnos())
          .thenAnswer((_) async => Error(errorMessage));

      // Act
      final result = await getAlumnosUseCase.run();

      // Assert
      expect(result, isA<Error>());
      expect((result as Error).msg, equals(errorMessage));
    });

    test('debe retornar Error cuando hay error de conexión', () async {
      // Arrange
      const errorMessage = 'Error de conexión';
      when(() => mockHomeRepository.getAlumnos())
          .thenAnswer((_) async => Error(errorMessage));

      // Act
      final result = await getAlumnosUseCase.run();

      // Assert
      expect(result, isA<Error>());
      expect((result as Error).msg, equals(errorMessage));
    });

    test('debe llamar al repositorio exactamente una vez', () async {
      // Arrange
      when(() => mockHomeRepository.getAlumnos())
          .thenAnswer((_) async => Success(TestAlumnoResponse.valid));

      // Act
      await getAlumnosUseCase.run();

      // Assert
      verify(() => mockHomeRepository.getAlumnos()).called(1);
      verifyNoMoreInteractions(mockHomeRepository);
    });
  });
}
