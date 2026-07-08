/// Tests unitarios para HomeService.
///
/// Blindan el parseo de alumnos y el manejo de sesión/errores ante breaking
/// changes del paquete `http` o del contrato del backend. Se mockea
/// `AuthUseCases.getUserSession` (sesión) y se intercepta HTTP con
/// `http.runWithClient` — sin tocar código de producción.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late MockSharedPref mockSharedPref;
  late HomeService service;

  /// Configura la sesión que devolverá el mock de getUserSession.
  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    mockSharedPref = MockSharedPref();
    service = HomeService(
      mockSharedPref,
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('HomeService.getAlumnos', () {
    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getAlumnos(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoSession);
    });

    test('devuelve Error(errorNoToken) cuando el token está vacío', () async {
      conSesion(AuthResponse(
        status: 200,
        msg: 'ok',
        accessToken: '',
        tokenType: 'Bearer',
        user: TestUser.valid,
        apiVersion: '1.0.0',
        appVersion: '1.0.0',
      ));

      final result = await http.runWithClient(
          () => service.getAlumnos(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success<AlumnoResponse> con la lista parseada (200)',
        () async {
      conSesion(TestAuthResponse.valid);
      final client =
          _responde(json.encode(TestAlumnoResponse.validJson), 200);

      final result =
          await http.runWithClient(() => service.getAlumnos(), () => client);

      final data = (result as Success<AlumnoResponse>).data;
      expect(data.alumnos.length, 2);
      expect(data.familia, 'Familia López García');
    });

    test('devuelve Error ante status no exitoso', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode({'msg': 'No encontrado'}), 404);

      final result =
          await http.runWithClient(() => service.getAlumnos(), () => client);

      expect((result as Error).msg, 'No encontrado');
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getAlumnos(), () => _lanza(TimeoutException('t')));

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getAlumnos(),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });
}
