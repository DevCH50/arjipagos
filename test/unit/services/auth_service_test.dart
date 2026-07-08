/// Tests unitarios para AuthService.
///
/// Estos tests blindan el servicio ante breaking changes del paquete `http`
/// y ante cambios en el contrato JSON del backend. Se usa `runWithClient`
/// (package:http) para interceptar el cliente HTTP mediante una Zone SIN
/// modificar el código de producción (el servicio usa las funciones top-level
/// `http.post`, no un Client inyectado).
///
/// Cubre: login, register, cambiarContrasena y recuperarContrasena, incluyendo
/// las ramas de éxito, error lógico del servidor, 401, respuesta HTML no-JSON,
/// TimeoutException y SocketException.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/AuthService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_data.dart';

/// Construye un MockClient que responde con [body] y [status].
http.Client _clientQueResponde(String body, int status,
        {String contentType = 'application/json'}) =>
    MockClient((_) async =>
        http.Response(body, status, headers: {'content-type': contentType}));

/// Construye un MockClient que lanza [error] al hacer la petición.
http.Client _clientQueLanza(Object error) =>
    MockClient((_) async => throw error);

void main() {
  final service = AuthService();

  // ==========================================================================
  // login
  // ==========================================================================

  group('AuthService.login', () {
    test('devuelve Success<AuthResponse> con token válido (200)', () async {
      final client =
          _clientQueResponde(json.encode(TestAuthResponse.validJson), 200);

      final result =
          await http.runWithClient(() => service.login('user', 'pass'), () => client);

      expect(result, isA<Success<AuthResponse>>());
      expect((result as Success<AuthResponse>).data.accessToken,
          TestAuthResponse.valid.accessToken);
    });

    test('devuelve Error cuando el 200 no trae access_token', () async {
      final client = _clientQueResponde(
          json.encode({'msg': 'Credenciales incorrectas'}), 200);

      final result =
          await http.runWithClient(() => service.login('user', 'bad'), () => client);

      expect(result, isA<Error>());
      expect((result as Error).msg, 'Credenciales incorrectas');
    });

    test('devuelve Error ante status HTTP no exitoso (401)', () async {
      final client =
          _clientQueResponde(json.encode({'msg': 'No autorizado'}), 401);

      final result =
          await http.runWithClient(() => service.login('user', 'pass'), () => client);

      expect(result, isA<Error>());
      expect((result as Error).msg, 'No autorizado');
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      final client = _clientQueLanza(TimeoutException('timeout'));

      final result =
          await http.runWithClient(() => service.login('user', 'pass'), () => client);

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      final client = _clientQueLanza(const SocketException('sin red'));

      final result =
          await http.runWithClient(() => service.login('user', 'pass'), () => client);

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });

  // ==========================================================================
  // register
  // ==========================================================================

  group('AuthService.register', () {
    Future<Resource<String>> register(http.Client client) => http.runWithClient(
          () => service.register(
            nombre: 'Juan',
            apPaterno: 'Pérez',
            apMaterno: 'García',
            celular: '5551234567',
            email: 'juan@ejemplo.com',
            password: 'secret123',
          ),
          () => client,
        );

    test('devuelve Success con mensaje en 201', () async {
      final client =
          _clientQueResponde(json.encode({'message': 'Registro exitoso'}), 201);

      final result = await register(client);

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'Registro exitoso');
    });

    test('devuelve Error ante status no exitoso', () async {
      final client = _clientQueResponde(
          json.encode({'msg': 'El email ya existe'}), 422);

      final result = await register(client);

      expect((result as Error).msg, 'El email ya existe');
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      final result = await register(_clientQueLanza(const SocketException('x')));
      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });

  // ==========================================================================
  // cambiarContrasena
  // ==========================================================================

  group('AuthService.cambiarContrasena', () {
    Future<Resource<String>> cambiar(http.Client client) => http.runWithClient(
          () => service.cambiarContrasena(
            token: 'jwt',
            userId: 1,
            passwordActual: 'old',
            passwordNuevo: 'new12345',
          ),
          () => client,
        );

    test('devuelve Success con mensaje en 200', () async {
      final client = _clientQueResponde(
          json.encode({'message': 'Contraseña actualizada'}), 200);

      final result = await cambiar(client);

      expect((result as Success<String>).data, 'Contraseña actualizada');
    });

    test('devuelve Error cuando el backend responde status:0 (error lógico)',
        () async {
      final client = _clientQueResponde(
          json.encode({'status': 0, 'message': 'La contraseña actual no coincide'}),
          200);

      final result = await cambiar(client);

      expect((result as Error).msg, 'La contraseña actual no coincide');
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      final client = _clientQueResponde(json.encode({'msg': 'no'}), 401);

      final result = await cambiar(client);

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });

    test('devuelve Error legible cuando el servidor responde HTML no-JSON',
        () async {
      final client = _clientQueResponde(
          '<!DOCTYPE html><html><body>500</body></html>', 500,
          contentType: 'text/html');

      final result = await cambiar(client);

      expect(result, isA<Error>());
      // No debe intentar parsear el HTML: retorna un mensaje controlado.
      expect((result as Error).msg, contains('500'));
    });
  });

  // ==========================================================================
  // recuperarContrasena
  // ==========================================================================

  group('AuthService.recuperarContrasena', () {
    Future<Resource<String>> recuperar(http.Client client) => http.runWithClient(
          () => service.recuperarContrasena(
            username: 'juanperez',
            email: 'juan@ejemplo.com',
            deviceName: 'Pixel 8',
          ),
          () => client,
        );

    test('devuelve Success con mensaje en 200', () async {
      final client = _clientQueResponde(
          json.encode({'message': 'Revisa tu correo'}), 200);

      final result = await recuperar(client);

      expect((result as Success<String>).data, 'Revisa tu correo');
    });

    test('devuelve Error cuando el backend responde status:0', () async {
      final client = _clientQueResponde(
          json.encode({'status': 0, 'msg': 'Usuario no encontrado'}), 200);

      final result = await recuperar(client);

      expect((result as Error).msg, 'Usuario no encontrado');
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      final result =
          await recuperar(_clientQueLanza(TimeoutException('t')));
      expect((result as Error).msg, AppStrings.errorTimeout);
    });
  });
}
