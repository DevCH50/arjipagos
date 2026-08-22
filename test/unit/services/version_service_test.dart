/// Tests unitarios de VersionService.
///
/// Blindan el contrato de `/api/v1/app/version`: que se mande el parámetro
/// `plataforma`, que el JSON se parsee de forma tolerante y —sobre todo— que
/// **ningún fallo devuelva datos que puedan bloquear al usuario**. Un error de
/// red tiene que acabar en [Error], nunca en un [Success] con un mínimo
/// inventado.
///
/// Se intercepta HTTP con `http.runWithClient`, igual que el resto de servicios.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/VersionService.dart';
import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

void main() {
  late VersionService service;

  setUp(() {
    service = VersionService();
  });

  group('VersionService.getVersion', () {
    test('parsea la política completa', () async {
      final cuerpo = json.encode({
        'build_minimo': 34,
        'build_recomendado': 35,
        'version_minima': '1.0.25',
        'version_recomendada': '1.0.26',
        'url_tienda': 'https://play.google.com/store/apps/details?id=mx.moriah.arjipagos',
        'mensaje': 'Actualiza para seguir usando ArjiPagos',
        'mantenimiento': false,
      });

      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde(cuerpo, 200),
      );

      final version = (result as Success<VersionApp>).data;
      expect(version.buildMinimo, 34);
      expect(version.buildRecomendado, 35);
      expect(version.versionMinima, '1.0.25');
      expect(version.mensaje, 'Actualiza para seguir usando ArjiPagos');
      expect(version.mantenimiento, isFalse);
    });

    test('manda el parámetro plataforma en la URL', () async {
      Uri? capturada;

      final result = await http.runWithClient(
        () => service.getVersion(),
        () => MockClient((request) async {
          capturada = request.url;
          return http.Response('{}', 200);
        }),
      );

      expect(result, isA<Success<VersionApp>>());
      expect(capturada?.path, '/api/v1/app/version');
      // Los tests corren en el escritorio, donde `Platform.isIOS` es falso.
      expect(capturada?.queryParameters['plataforma'], 'android');
    });

    test('acepta números serializados como texto', () async {
      final cuerpo = json.encode({
        'build_minimo': '34',
        'mantenimiento': '1',
      });

      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde(cuerpo, 200),
      );

      final version = (result as Success<VersionApp>).data;
      expect(version.buildMinimo, 34);
      expect(version.mantenimiento, isTrue);
    });

    test('un JSON vacío no bloquea a nadie', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde('{}', 200),
      );

      final version = (result as Success<VersionApp>).data;
      expect(version.buildMinimo, isNull);
      expect(version.versionMinima, isNull);
      expect(version.mantenimiento, isFalse);
    });

    test('un build mínimo en cero se descarta', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde(json.encode({'build_minimo': 0}), 200),
      );

      expect((result as Success<VersionApp>).data.buildMinimo, isNull);
    });

    test('devuelve Error si el endpoint todavía no existe (404)', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde('{"message":"Not Found"}', 404),
      );

      expect((result as Error).msg, AppStrings.errorServidorNoDisponible);
    });

    test('devuelve Error cuando Laravel responde una página HTML', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde('<!DOCTYPE html><html><body>500</body></html>', 500),
      );

      expect((result as Error).msg, AppStrings.errorServidorNoDisponible);
    });

    test('devuelve Error cuando el cuerpo no es un objeto JSON', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _responde('[1,2,3]', 200),
      );

      expect((result as Error).msg, AppStrings.errorRespuestaInvalida);
    });

    test('devuelve Error(errorTimeout) si el servidor no responde', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _lanza(TimeoutException('sin respuesta')),
      );

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('devuelve Error(errorConnection) si no hay red', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _lanza(const SocketException('sin red')),
      );

      expect((result as Error).msg, AppStrings.errorConnection);
    });

    test('nunca filtra la excepción cruda al usuario', () async {
      final result = await http.runWithClient(
        () => service.getVersion(),
        () => _lanza(const HandshakeException('cadena TLS incompleta')),
      );

      final mensaje = (result as Error).msg;
      expect(mensaje, AppStrings.errorConexionSegura);
      expect(mensaje.contains('Handshake'), isFalse);
    });
  });
}
