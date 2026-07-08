/// Tests unitarios para NotificacionService.
///
/// Blindan el parseo de la lista/conteo de notificaciones y el marcado como
/// leídas ante breaking changes de `http` o del contrato del backend. Se
/// mockea `AuthUseCases.getUserSession` y se intercepta HTTP con
/// `http.runWithClient` (sin tocar producción).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/NotificacionService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
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
  late NotificacionService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = NotificacionService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  // ==========================================================================
  // getNotificaciones
  // ==========================================================================

  group('NotificacionService.getNotificaciones', () {
    test('devuelve Error(errorNoSession) sin sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getNotificaciones(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoSession);
    });

    test('devuelve Success con la lista parseada (200)', () async {
      conSesion(TestAuthResponse.valid);
      final body = json.encode({
        'data': [
          TestNotificacion.noLeida.toJson(),
          TestNotificacion.leida.toJson(),
        ],
        'no_leidas': 1,
      });
      final client = _responde(body, 200);

      final result = await http.runWithClient(
          () => service.getNotificaciones(page: 1), () => client);

      final data = (result as Success<List<Notificacion>>).data;
      expect(data.length, 2);
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode({'msg': 'no'}), 401);

      final result = await http.runWithClient(
          () => service.getNotificaciones(), () => client);

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });

    test('devuelve Error legible cuando el servidor responde HTML', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('<!DOCTYPE html><html></html>', 500);

      final result = await http.runWithClient(
          () => service.getNotificaciones(), () => client);

      expect((result as Error).msg, contains('no está disponible'));
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getNotificaciones(),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });

  // ==========================================================================
  // getCountNoLeidas
  // ==========================================================================

  group('NotificacionService.getCountNoLeidas', () {
    test('devuelve Success con el conteo del backend', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode({'no_leidas': 7}), 200);

      final result = await http.runWithClient(
          () => service.getCountNoLeidas(), () => client);

      expect((result as Success<int>).data, 7);
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode({'msg': 'no'}), 401);

      final result = await http.runWithClient(
          () => service.getCountNoLeidas(), () => client);

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });
  });

  // ==========================================================================
  // marcarLeida / marcarTodasLeidas
  // ==========================================================================

  group('NotificacionService.marcarLeida', () {
    test('devuelve Success(true) en 200', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('{}', 200);

      final result =
          await http.runWithClient(() => service.marcarLeida(5), () => client);

      expect((result as Success<bool>).data, true);
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('{}', 401);

      final result =
          await http.runWithClient(() => service.marcarLeida(5), () => client);

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.marcarLeida(5), () => _lanza(TimeoutException('t')));

      expect((result as Error).msg, AppStrings.errorTimeout);
    });
  });

  group('NotificacionService.marcarTodasLeidas', () {
    test('devuelve Success(true) en 200', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('{}', 200);

      final result = await http.runWithClient(
          () => service.marcarTodasLeidas(), () => client);

      expect((result as Success<bool>).data, true);
    });
  });
}
