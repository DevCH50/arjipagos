/// Tests unitarios para EdoCtaService.
///
/// Blindan el parseo de estados de cuenta y el manejo de sesión/errores ante
/// breaking changes de `http` o del contrato del backend. Se mockea
/// `AuthUseCases.getUserSession` y se intercepta HTTP con `http.runWithClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
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

/// JSON válido de estados de cuenta reutilizando los alumnos de prueba.
Map<String, dynamic> get _edoCtaJson => {
      'ciclo_predeterminado_id': 2024,
      'familia_id': 1,
      'familia': 'Familia López García',
      'alumnos': TestAlumno.listaJson,
      'success': true,
      'message': 'ok',
    };

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late EdoCtaService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = EdoCtaService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('EdoCtaService.getEstadosDeCuenta', () {
    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuenta(), () => _responde('{}', 200));

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
          () => service.getEstadosDeCuenta(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success con los alumnos parseados (200)', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode(_edoCtaJson), 200);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuenta(), () => client);

      final data = (result as Success<EstadosDeCuentaResponse>).data;
      expect(data.alumnos.length, 2);
      expect(data.familia, 'Familia López García');
    });

    test('devuelve Error legible cuando el servidor responde HTML', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(
          '<!DOCTYPE html><html><body>error</body></html>', 500);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuenta(), () => client);

      expect(result, isA<Error>());
      expect((result as Error).msg, contains('no está disponible'));
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuenta(),
          () => _lanza(TimeoutException('t')));

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuenta(),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });
}
