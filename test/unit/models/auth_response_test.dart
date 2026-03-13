/// Tests unitarios para el modelo AuthResponse.
library;

import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('AuthResponse', () {
    group('fromJson', () {
      test('debe crear un AuthResponse válido desde JSON', () {
        // Arrange
        final json = TestAuthResponse.validJson;

        // Act
        final authResponse = AuthResponse.fromJson(json);

        // Assert
        expect(authResponse.status, equals(200));
        expect(authResponse.msg, equals('Login exitoso'));
        expect(authResponse.accessToken, isNotEmpty);
        expect(authResponse.tokenType, equals('Bearer'));
        expect(authResponse.apiVersion, equals('1.0.0'));
        expect(authResponse.appVersion, equals('1.0.0'));
      });

      test('debe parsear el User embebido correctamente', () {
        // Arrange
        final json = TestAuthResponse.validJson;

        // Act
        final authResponse = AuthResponse.fromJson(json);

        // Assert
        expect(authResponse.user, isNotNull);
        expect(authResponse.user.id, equals(1));
        expect(authResponse.user.username, equals('juanperez'));
        expect(authResponse.user.email, equals('juan@ejemplo.com'));
      });

      test('debe manejar token JWT correctamente', () {
        // Arrange
        final json = TestAuthResponse.validJson;

        // Act
        final authResponse = AuthResponse.fromJson(json);

        // Assert
        expect(authResponse.accessToken, startsWith('eyJ'));
        expect(authResponse.tokenType, equals('Bearer'));
      });
    });

    group('toJson', () {
      test('debe serializar AuthResponse a JSON correctamente', () {
        // Arrange
        final authResponse = TestAuthResponse.valid;

        // Act
        final json = authResponse.toJson();

        // Assert
        expect(json['status'], equals(200));
        expect(json['msg'], equals('Login exitoso'));
        expect(json['access_token'], isNotEmpty);
        expect(json['token_type'], equals('Bearer'));
        expect(json['user'], isA<Map<String, dynamic>>());
      });

      test('debe incluir User serializado correctamente', () {
        // Arrange
        final authResponse = TestAuthResponse.valid;

        // Act
        final json = authResponse.toJson();
        final userJson = json['user'] as Map<String, dynamic>;

        // Assert
        expect(userJson['id'], equals(1));
        expect(userJson['username'], equals('juanperez'));
      });
    });

    group('authResponseFromJson helper', () {
      test('debe parsear JSON string a AuthResponse', () {
        // Arrange
        const jsonString = '''
        {
          "status": 200,
          "msg": "OK",
          "access_token": "token123",
          "token_type": "Bearer",
          "user": {
            "id": 1,
            "username": "test",
            "email": "test@test.com",
            "nombre": "Test",
            "ap_paterno": "User",
            "ap_materno": "Test",
            "curp": "TEST123",
            "emails": "test@test.com",
            "celulares": "123",
            "telefonos": "456",
            "fecha_nacimiento": null,
            "genero": 1,
            "uuid": "uuid",
            "activo": 1,
            "full_name": "Test User",
            "full_name_with_username": "Test User (test)",
            "path_image_profile": ""
          },
          "api_version": "1.0",
          "app_version": "1.0"
        }
        ''';

        // Act
        final authResponse = authResponseFromJson(jsonString);

        // Assert
        expect(authResponse.status, equals(200));
        expect(authResponse.user.username, equals('test'));
      });
    });

    group('authResponseToJson helper', () {
      test('debe convertir AuthResponse a JSON string', () {
        // Arrange
        final authResponse = TestAuthResponse.valid;

        // Act
        final jsonString = authResponseToJson(authResponse);

        // Assert
        expect(jsonString, contains('"status":200'));
        expect(jsonString, contains('"msg":"Login exitoso"'));
        expect(jsonString, contains('"access_token"'));
      });
    });
  });
}
