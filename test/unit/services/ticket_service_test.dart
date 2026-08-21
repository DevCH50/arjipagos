/// Tests unitarios para TicketService.
///
/// Blindan lo que distingue un ticket real de un error disfrazado: la sesión,
/// el content-type y el cuerpo vacío. El caso del `content-type` no PDF es el
/// más importante: `http` sigue los redirects por su cuenta, así que un `302`
/// hacia la página de login llega como un `200` lleno de HTML y sin esa
/// verificación se guardaría en disco como si fuera el comprobante.
///
/// Se mockea `AuthUseCases.getUserSession` y se intercepta HTTP con
/// `http.runWithClient`.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/TicketService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// URL de ticket con la forma real que envía el backend en producción.
const String _urlTicket =
    'https://arjipagos.moriah.mx/api/v1/tickets/a7064b3b-a517-4636-95da-c5b2cdcd19ff/print';

/// Cliente que responde con bytes y el content-type indicado.
http.Client _respondeBytes(
  List<int> bytes,
  int status, {
  String contentType = 'application/pdf',
}) =>
    MockClient((_) async => http.Response.bytes(
          bytes,
          status,
          headers: {'content-type': contentType},
        ));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

/// Bytes mínimos con la firma de un PDF real.
final Uint8List _pdf = Uint8List.fromList('%PDF-1.4 contenido'.codeUnits);

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late TicketService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = TicketService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('TicketService.descargarTicket', () {
    test('devuelve Error(ticketNoDisponible) cuando la URL viene vacía',
        () async {
      final result = await service.descargarTicket('');

      expect((result as Error).msg, AppStrings.ticketNoDisponible);
    });

    test('no consulta la sesión si la URL viene vacía', () async {
      await service.descargarTicket('');

      verifyNever(() => mockGetUserSession.run());
    });

    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(_pdf, 200),
      );

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
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(_pdf, 200),
      );

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success con los bytes del PDF (200)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(_pdf, 200),
      );

      expect(result, isA<Success<Uint8List>>());
      expect((result as Success<Uint8List>).data, _pdf);
    });

    test('manda el Bearer token de la sesión en la petición', () async {
      conSesion(TestAuthResponse.valid);
      String? autorizacion;

      final client = MockClient((request) async {
        autorizacion = request.headers['Authorization'];
        return http.Response.bytes(
          _pdf,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => client,
      );

      expect(autorizacion, 'Bearer ${TestAuthResponse.valid.accessToken}');
    });

    test('repara la URL con localhost que manda el backend de desarrollo',
        () async {
      conSesion(TestAuthResponse.valid);
      Uri? pedida;

      final client = MockClient((request) async {
        pedida = request.url;
        return http.Response.bytes(
          _pdf,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      await http.runWithClient(
        () => service.descargarTicket(
          'http://localhost:8000/api/v1/tickets/a7064b3b-a517/print',
        ),
        () => client,
      );

      // `localhost` no resuelve desde el emulador ni desde un teléfono físico.
      expect(pedida!.host, isNot('localhost'));
      expect(pedida!.path, '/api/v1/tickets/a7064b3b-a517/print');
    });

    test('no toca la URL de producción', () async {
      conSesion(TestAuthResponse.valid);
      Uri? pedida;

      final client = MockClient((request) async {
        pedida = request.url;
        return http.Response.bytes(
          _pdf,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => client,
      );

      expect(pedida.toString(), _urlTicket);
    });

    test('devuelve Error(ticketSesionExpirada) con 401', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(const [], 401),
      );

      expect((result as Error).msg, AppStrings.ticketSesionExpirada);
    });

    test('devuelve Error(ticketSesionExpirada) con 403', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(const [], 403),
      );

      expect((result as Error).msg, AppStrings.ticketSesionExpirada);
    });

    test('devuelve Error(ticketErrorCarga) con 500', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(const [], 500),
      );

      expect((result as Error).msg, AppStrings.ticketErrorCarga);
    });

    test(
        'rechaza un 200 que en realidad es el HTML del login '
        '(redirect seguido por http)', () async {
      conSesion(TestAuthResponse.valid);
      final html = '<html><body>Iniciar sesión</body></html>'.codeUnits;

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(html, 200, contentType: 'text/html; charset=UTF-8'),
      );

      expect((result as Error).msg, AppStrings.ticketSesionExpirada);
    });

    test('devuelve Error(ticketErrorCarga) si el PDF llega vacío', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _respondeBytes(const [], 200),
      );

      expect((result as Error).msg, AppStrings.ticketErrorCarga);
    });

    test('devuelve Error(errorTimeout) ante TimeoutException', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _lanza(TimeoutException('timeout')),
      );

      expect((result as Error).msg, AppStrings.errorTimeout);
    });

    test('devuelve Error(errorConnection) ante SocketException', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _lanza(const SocketException('sin red')),
      );

      expect((result as Error).msg, AppStrings.errorConnection);
    });

    test('nunca filtra la excepción cruda al usuario', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.descargarTicket(_urlTicket),
        () => _lanza(const HandshakeException('cadena TLS incompleta')),
      );

      expect((result as Error).msg, isNot(contains('HandshakeException')));
    });
  });
}
