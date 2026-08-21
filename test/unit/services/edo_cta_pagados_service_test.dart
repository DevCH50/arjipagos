/// Tests unitarios para EdoCtaPagadosService.
///
/// Blindan el parseo de los pagos realizados y el manejo de sesión/errores ante
/// breaking changes de `http` o del contrato del backend. Se mockea
/// `AuthUseCases.getUserSession` y se intercepta HTTP con `http.runWithClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaPagadosService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
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

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late EdoCtaPagadosService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = EdoCtaPagadosService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('EdoCtaPagadosService.getEstadosDeCuentaPagados', () {
    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(), () => _responde('{}', 200));

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
          () => service.getEstadosDeCuentaPagados(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success con los pagos realizados parseados (200)', () async {
      conSesion(TestAuthResponse.valid);
      final client =
          _responde(json.encode(TestPagoRealizado.respuestaJson), 200);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(), () => client);

      final data = (result as Success<EstadosDeCuentaResponse>).data;
      expect(data.alumnos, hasLength(1));
      expect(data.familia, equals('DAMASCO CANELLA'));

      final pagos = data.alumnos.first.estadoDeCuenta;
      expect(pagos, hasLength(2));
      expect(pagos.first.estadoPago, equals(EstadoPago.pagado));
      expect(pagos.first.ticketFolio, equals('T7672'));
      expect(pagos.first.tieneTicket, isTrue);
    });

    test('devuelve Error legible cuando el servidor responde HTML', () async {
      conSesion(TestAuthResponse.valid);
      final client =
          _responde('<!DOCTYPE html><html><body>error</body></html>', 500);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(), () => client);

      expect(result, isA<Error>());
      expect((result as Error).msg, contains('no está disponible'));
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(),
          () => _lanza(TimeoutException('t')));

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });

    test('nunca expone la excepción cruda al usuario', () async {
      conSesion(TestAuthResponse.valid);

      // Un HandshakeException fue el incidente real del 2026-08-13.
      final result = await http.runWithClient(
          () => service.getEstadosDeCuentaPagados(),
          () => _lanza(const HandshakeException('cadena TLS incompleta')));

      final msg = (result as Error).msg;
      expect(msg, isNot(contains('HandshakeException')));
      expect(msg, isNot(contains('cadena TLS incompleta')));
    });
  });
}
