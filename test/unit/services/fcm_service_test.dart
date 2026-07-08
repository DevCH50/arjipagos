/// Tests unitarios para la parte REST de FcmService.
///
/// IMPORTANTE: solo se cubren los métodos que hacen HTTP puro
/// (`registrarToken` POST, `eliminarToken` DELETE) y `obtenerTipoDispositivo`.
/// Los métodos que usan `FirebaseMessaging.instance` (`obtenerToken`) y
/// `flutter_local_notifications` (`configurarHandlers`, canales, `show`) son
/// platform-channel y NO son unit-testeables: su cobertura real es el build +
/// smoke en dispositivo (validado en la evaluación de FLN 22).
///
/// Se intercepta HTTP con `http.runWithClient` sin tocar código de producción.
library;

import 'dart:async';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client _responde(int status) =>
    MockClient((_) async => http.Response('{}', status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

void main() {
  final service = FcmService();

  // ==========================================================================
  // registrarToken (POST)
  // ==========================================================================

  group('FcmService.registrarToken', () {
    test('devuelve Error(errorNoToken) si authToken está vacío', () async {
      final result = await service.registrarToken(
          authToken: '', fcmToken: 'fcm', mobileType: 'android');

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Error si el fcmToken está vacío', () async {
      final result = await service.registrarToken(
          authToken: 'jwt', fcmToken: '', mobileType: 'android');

      expect(result, isA<Error>());
    });

    test('devuelve Success(true) en 200', () async {
      final result = await http.runWithClient(
        () => service.registrarToken(
            authToken: 'jwt', fcmToken: 'fcm', mobileType: 'android'),
        () => _responde(200),
      );

      expect((result as Success<bool>).data, true);
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      final result = await http.runWithClient(
        () => service.registrarToken(
            authToken: 'jwt', fcmToken: 'fcm', mobileType: 'ios'),
        () => _responde(401),
      );

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      final result = await http.runWithClient(
        () => service.registrarToken(
            authToken: 'jwt', fcmToken: 'fcm', mobileType: 'android'),
        () => _lanza(const SocketException('x')),
      );

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });

  // ==========================================================================
  // eliminarToken (DELETE)
  // ==========================================================================

  group('FcmService.eliminarToken', () {
    test('devuelve Error si falta authToken o fcmToken', () async {
      final result =
          await service.eliminarToken(authToken: '', fcmToken: 'fcm');

      expect(result, isA<Error>());
    });

    test('devuelve Success(true) en 204', () async {
      final result = await http.runWithClient(
        () => service.eliminarToken(authToken: 'jwt', fcmToken: 'fcm'),
        () => _responde(204),
      );

      expect((result as Success<bool>).data, true);
    });

    test('devuelve Error(errorUnauthorized) ante 401', () async {
      final result = await http.runWithClient(
        () => service.eliminarToken(authToken: 'jwt', fcmToken: 'fcm'),
        () => _responde(401),
      );

      expect((result as Error).msg, AppStrings.errorUnauthorized);
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      final result = await http.runWithClient(
        () => service.eliminarToken(authToken: 'jwt', fcmToken: 'fcm'),
        () => _lanza(TimeoutException('t')),
      );

      expect((result as Error).msg, AppStrings.errorTimeout);
    });
  });

  // ==========================================================================
  // obtenerTipoDispositivo (lógica pura)
  // ==========================================================================

  group('FcmService.obtenerTipoDispositivo', () {
    test('devuelve "android" o "ios" según la plataforma', () {
      final tipo = service.obtenerTipoDispositivo();
      expect(tipo, anyOf('android', 'ios'));
    });
  });
}
