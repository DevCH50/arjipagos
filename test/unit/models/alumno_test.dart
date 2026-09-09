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
        expect(alumno.familia, equals('Familia López García'));
        expect(alumno.alumno, equals('LOPEZ GARCIA MARIA'));
        expect(alumno.nombre, equals('María'));
        expect(alumno.esBaja, isFalse);
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
        expect(alumno.urlPhoto, isEmpty);
      });

      // El backend dejó de mandar estos campos el 2026-09-09 (ver el modelo).
      // Un servidor sin actualizar los sigue enviando, así que el parseo tiene
      // que ignorarlos sin enterarse — y `toJson` no puede resucitarlos.
      test('ignora los campos que el backend ya no manda', () {
        // Arrange: la respuesta de ANTES del recorte, con todo lo retirado.
        final json = {
          'alumno_id': 3,
          'familia_id': 7,
          'familia': 'Familia Test',
          'alumno': 'Test',
          'ap_paterno': 'Paterno',
          'ap_materno': 'Materno',
          'nombre': 'Test',
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
        final serializado = alumno.toJson();

        // Assert: lo que sí se usa sigue llegando…
        expect(alumno.alumnoId, equals(3));
        expect(alumno.nombre, equals('Test'));
        expect(alumno.grupo, equals('1ro A'));
        expect(alumno.esBaja, isFalse);

        // …y lo retirado no reaparece por la puerta de atrás.
        for (final clave in const [
          'familia_id',
          'ap_paterno',
          'ap_materno',
          'beca_sep',
          'beca_arji',
          'beca_bach',
          'beca_sp',
          'grupo_id',
        ]) {
          expect(
            serializado.containsKey(clave),
            isFalse,
            reason: '`$clave` se retiró del modelo: no debe volver a toJson()',
          );
        }
      });

      test('debe usar valores por defecto si falta la familia', () {
        // Arrange
        final json = {
          'alumno_id': 4,
          'alumno': 'Sin familia',
          'estado_de_cuenta': [],
        };

        // Act
        final alumno = Alumno.fromJson(json);

        // Assert
        expect(alumno.familia, isEmpty);
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
        expect(json['familia'], equals('Familia López García'));
        expect(json['alumno'], equals('LOPEZ GARCIA MARIA'));
        expect(json['nombre'], equals('María'));
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
