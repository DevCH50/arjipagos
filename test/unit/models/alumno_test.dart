/// Tests unitarios para el modelo Alumno.
library;

import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('Alumno', () {
    group('fromJson', () {
      test('debe crear un Alumno activo desde JSON', () {
        // Arrange
        final json = TestAlumno.activoJson;

        // Act
        final alumno = Alumno.fromJson(json);

        // Assert
        expect(alumno.alumnoId, equals(1));
        expect(alumno.alumno, equals('LOPEZ GARCIA MARIA'));
        expect(alumno.nombre, equals('María'));
        expect(alumno.apPaterno, equals('López'));
        expect(alumno.apMaterno, equals('García'));
        expect(alumno.becaSep, equals('Sí'));
        expect(alumno.becaArji, equals('No'));
        expect(alumno.esBaja, isFalse);
        expect(alumno.grupoId, equals(101));
        expect(alumno.grupo, equals('3ro A'));
        expect(alumno.urlPhoto, isNotEmpty);
      });

      test('debe crear un Alumno dado de baja desde JSON', () {
        // Arrange
        final json = TestAlumno.bajaJson;

        // Act
        final alumno = Alumno.fromJson(json);

        // Assert
        expect(alumno.alumnoId, equals(2));
        expect(alumno.alumno, equals('SANCHEZ MARTINEZ PEDRO'));
        expect(alumno.nombre, equals('Pedro'));
        expect(alumno.esBaja, isTrue);
        expect(alumno.becaArji, equals('Sí'));
        expect(alumno.urlPhoto, isEmpty);
      });

      test('debe manejar todos los tipos de beca', () {
        // Arrange
        final json = {
          'alumno_id': 3,
          'alumno': 'Test',
          'beca_sep': 'Completa',
          'beca_arji': 'Parcial',
          'beca_bach': 'Media',
          'beca_sp': 'No',
          'es_baja': false,
          'grupo_id': 1,
          'grupo': '1ro A',
          'url_photo': '',
          'estado_de_cuenta': [],
        };

        // Act
        final alumno = Alumno.fromJson(json);

        // Assert
        expect(alumno.becaSep, equals('Completa'));
        expect(alumno.becaArji, equals('Parcial'));
        expect(alumno.becaBach, equals('Media'));
        expect(alumno.becaSp, equals('No'));
      });
    });

    group('toJson', () {
      test('debe serializar Alumno a JSON correctamente', () {
        // Arrange
        final alumno = TestAlumno.activo;

        // Act
        final json = alumno.toJson();

        // Assert
        expect(json['alumno_id'], equals(1));
        expect(json['alumno'], equals('LOPEZ GARCIA MARIA'));
        expect(json['nombre'], equals('María'));
        expect(json['beca_sep'], equals('Sí'));
        expect(json['es_baja'], isFalse);
        expect(json['grupo'], equals('3ro A'));
      });

      test('fromJson y toJson deben ser operaciones inversas', () {
        // Arrange
        final originalJson = TestAlumno.activoJson;

        // Act
        final alumno = Alumno.fromJson(originalJson);
        final resultJson = alumno.toJson();

        // Assert
        expect(resultJson, equals(originalJson));
      });
    });

    group('propiedades', () {
      test('esBaja debe reflejar el estado correcto', () {
        // Arrange & Act
        final alumnoActivo = TestAlumno.activo;
        final alumnoBaja = TestAlumno.baja;

        // Assert
        expect(alumnoActivo.esBaja, isFalse);
        expect(alumnoBaja.esBaja, isTrue);
      });
    });
  });
}
