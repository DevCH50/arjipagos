/// Tests unitarios para BannerService.
///
/// Blindan el contrato de `/api/v1/banners`: que se mande el `user_id` de la
/// sesión en el body con Bearer token, que la lista se parsee y que ningún
/// fallo de red llegue crudo a la pantalla.
///
/// Se mockea `AuthUseCases.getUserSession` y se intercepta HTTP con
/// `http.runWithClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/BannerService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
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
  late BannerService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = BannerService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('BannerService.getBanners', () {
    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getBanners(), () => _responde('{}', 200));

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
          () => service.getBanners(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success con los banners parseados (200)', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode(TestBanner.respuestaJson), 200);

      final result =
          await http.runWithClient(() => service.getBanners(), () => client);

      expect(result, isA<Success<BannersResponse>>());
      final data = (result as Success<BannersResponse>).data;
      expect(data.banners, hasLength(2));
      expect(data.banners.first.titulo, contains('descuento especial'));
    });

    test('manda el user_id de la sesión en el body y el Bearer token',
        () async {
      conSesion(TestAuthResponse.valid);
      Map<String, dynamic>? bodyEnviado;
      String? autorizacion;
      String? metodo;

      final client = MockClient((request) async {
        metodo = request.method;
        autorizacion = request.headers['Authorization'];
        bodyEnviado = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode(TestBanner.respuestaJson), 200);
      });

      await http.runWithClient(() => service.getBanners(), () => client);

      expect(metodo, 'POST');
      expect(bodyEnviado!['user_id'], TestAuthResponse.valid.user.id);
      expect(autorizacion, 'Bearer ${TestAuthResponse.valid.accessToken}');
    });

    test('una respuesta sin banners devuelve Success con lista vacía',
        () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode(TestBanner.respuestaVaciaJson), 200);

      final result =
          await http.runWithClient(() => service.getBanners(), () => client);

      expect((result as Success<BannersResponse>).data.banners, isEmpty);
    });

    test('detecta el HTML de un error 500 de Laravel', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('<!DOCTYPE html><html>Whoops</html>', 500);

      final result =
          await http.runWithClient(() => service.getBanners(), () => client);

      expect((result as Error).msg, AppStrings.errorServidorNoDisponible);
    });

    test('devuelve Error(errorTimeout) ante TimeoutException', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
          () => service.getBanners(), () => _lanza(TimeoutException('t')));

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('devuelve Error(errorConnection) ante SocketException', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(() => service.getBanners(),
          () => _lanza(const SocketException('sin red')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });

    test('nunca filtra la excepción cruda al usuario', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.getBanners(),
        () => _lanza(const HandshakeException('cadena TLS incompleta')),
      );

      expect((result as Error).msg, isNot(contains('HandshakeException')));
    });
  });
}
