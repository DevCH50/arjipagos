/// Tests unitarios para el modelo User.
library;

import 'package:arjipagos/src/domain/models/User.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('debe crear un User válido desde JSON', () {
        // Arrange
        final json = TestUser.validJson;

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, equals(1));
        expect(user.username, equals('juanperez'));
        expect(user.email, equals('juan@ejemplo.com'));
        expect(user.nombre, equals('Juan'));
        expect(user.apPaterno, equals('Pérez'));
        expect(user.apMaterno, equals('García'));
        expect(user.curp, equals('PEGJ900101HDFRRL09'));
        expect(user.fullName, equals('Juan Pérez García'));
        expect(user.activo, equals(1));
        expect(user.genero, equals(1));
      });

      test('debe manejar fechaNacimiento como String', () {
        // Arrange
        final json = TestUser.validJson;

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.fechaNacimiento, equals('1990-01-01'));
      });

      test('debe manejar fechaNacimiento como null', () {
        // Arrange
        final json = Map<String, dynamic>.from(TestUser.validJson);
        json['fecha_nacimiento'] = null;

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.fechaNacimiento, isNull);
      });
    });

    group('toJson', () {
      test('debe serializar User a JSON correctamente', () {
        // Arrange
        final user = TestUser.valid;

        // Act
        final json = user.toJson();

        // Assert
        expect(json['id'], equals(1));
        expect(json['username'], equals('juanperez'));
        expect(json['email'], equals('juan@ejemplo.com'));
        expect(json['nombre'], equals('Juan'));
        expect(json['ap_paterno'], equals('Pérez'));
        expect(json['ap_materno'], equals('García'));
        expect(json['full_name'], equals('Juan Pérez García'));
      });

      test('fromJson y toJson deben ser operaciones inversas', () {
        // Arrange
        final originalJson = TestUser.validJson;

        // Act
        final user = User.fromJson(originalJson);
        final resultJson = user.toJson();

        // Assert
        expect(resultJson['id'], equals(originalJson['id']));
        expect(resultJson['username'], equals(originalJson['username']));
        expect(resultJson['email'], equals(originalJson['email']));
        expect(resultJson['nombre'], equals(originalJson['nombre']));
        expect(resultJson['ap_paterno'], equals(originalJson['ap_paterno']));
      });
    });
  });
}
