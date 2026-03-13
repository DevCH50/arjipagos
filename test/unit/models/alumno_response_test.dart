/// Tests unitarios para el modelo AlumnoResponse.
library;

import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('AlumnoResponse', () {
    group('fromJson', () {
      test('debe crear un AlumnoResponse con alumnos desde JSON', () {
        // Arrange
        final json = TestAlumnoResponse.validJson;

        // Act
        final response = AlumnoResponse.fromJson(json);

        // Assert
        expect(response.familiaId, equals(1));
        expect(response.familia, equals('Familia López García'));
        expect(response.roleId, equals(2));
        expect(response.cicloPredeterminadoId, equals(2024));
        expect(response.cicloPredeterminado, equals('2024-2025'));
        expect(response.alumnos, hasLength(2));
      });

      test('debe crear un AlumnoResponse vacío desde JSON', () {
        // Arrange
        final json = TestAlumnoResponse.emptyJson;

        // Act
        final response = AlumnoResponse.fromJson(json);

        // Assert
        expect(response.alumnos, isEmpty);
        expect(response.familia, isNotEmpty);
      });

      test('debe parsear la lista de alumnos correctamente', () {
        // Arrange
        final json = TestAlumnoResponse.validJson;

        // Act
        final response = AlumnoResponse.fromJson(json);

        // Assert
        expect(response.alumnos[0].alumno, equals('María López'));
        expect(response.alumnos[0].esBaja, isFalse);
        expect(response.alumnos[1].alumno, equals('Pedro Sánchez'));
        expect(response.alumnos[1].esBaja, isTrue);
      });

      test('debe manejar ciclo escolar correctamente', () {
        // Arrange
        final json = TestAlumnoResponse.validJson;

        // Act
        final response = AlumnoResponse.fromJson(json);

        // Assert
        expect(response.cicloPredeterminadoId, equals(2024));
        expect(response.cicloPredeterminado, equals('2024-2025'));
      });
    });

    group('toJson', () {
      test('debe serializar AlumnoResponse a JSON correctamente', () {
        // Arrange
        final response = TestAlumnoResponse.valid;

        // Act
        final json = response.toJson();

        // Assert
        expect(json['familia_id'], equals(1));
        expect(json['familia'], equals('Familia López García'));
        expect(json['role_id'], equals(2));
        expect(json['alumnos'], isA<List>());
        expect(json['alumnos'] as List, hasLength(2));
      });

      test('debe serializar lista de alumnos correctamente', () {
        // Arrange
        final response = TestAlumnoResponse.valid;

        // Act
        final json = response.toJson();
        final alumnosJson = json['alumnos'] as List;

        // Assert
        expect(alumnosJson[0]['alumno'], equals('María López'));
        expect(alumnosJson[1]['alumno'], equals('Pedro Sánchez'));
      });

      test('fromJson y toJson deben ser operaciones inversas', () {
        // Arrange
        final originalJson = TestAlumnoResponse.validJson;

        // Act
        final response = AlumnoResponse.fromJson(originalJson);
        final resultJson = response.toJson();

        // Assert
        expect(resultJson['familia_id'], equals(originalJson['familia_id']));
        expect(resultJson['familia'], equals(originalJson['familia']));
        expect(
          (resultJson['alumnos'] as List).length,
          equals((originalJson['alumnos'] as List).length),
        );
      });
    });

    group('propiedades', () {
      test('debe tener la cantidad correcta de alumnos', () {
        // Arrange & Act
        final responseConAlumnos = TestAlumnoResponse.valid;
        final responseSinAlumnos = TestAlumnoResponse.empty;

        // Assert
        expect(responseConAlumnos.alumnos.length, equals(2));
        expect(responseSinAlumnos.alumnos.length, equals(0));
      });

      test('debe poder filtrar alumnos activos', () {
        // Arrange
        final response = TestAlumnoResponse.valid;

        // Act
        final alumnosActivos = response.alumnos.where((a) => !a.esBaja).toList();

        // Assert
        expect(alumnosActivos, hasLength(1));
        expect(alumnosActivos.first.alumno, equals('María López'));
      });

      test('debe poder filtrar alumnos dados de baja', () {
        // Arrange
        final response = TestAlumnoResponse.valid;

        // Act
        final alumnosBaja = response.alumnos.where((a) => a.esBaja).toList();

        // Assert
        expect(alumnosBaja, hasLength(1));
        expect(alumnosBaja.first.alumno, equals('Pedro Sánchez'));
      });
    });
  });
}
