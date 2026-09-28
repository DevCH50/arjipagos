/// Tests unitarios de `OpenpayService`.
///
/// Blindan el contrato de `POST /api/v1/openpay/crear-cargo`, que es lo único
/// que la app le pide al backend para cobrar «Otros pagos» (emisor fiscal 2):
///
/// - Que viaje la `referencia` y el `Bearer`, y que **NO viaje el importe**.
/// - Que un `success: false` enseñe el `message` del backend tal cual, sea cual
///   sea el código HTTP, porque ese texto está escrito para el tutor.
/// - Que un `success: true` sin URL usable se trate como fallo, y no acabe
///   abriendo el WebView en una pantalla en blanco.
/// - Que ningún fallo de red llegue crudo a la pantalla.
///
/// Se mockea `AuthUseCases.getUserSession` y se intercepta HTTP con
/// `http.runWithClient`, igual que el resto de services.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/OpenpayService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/OpenpayCheckout.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// Respuesta correcta del backend, la del camino feliz.
const String _urlOpenpay = 'https://sandbox-api.openpay.mx/ck/Cb0EJHFIp2aG';

String _cuerpoOk({String url = _urlOpenpay}) => json.encode({
  'success': true,
  'url': url,
  'order_id': '5358A5359A5360-N1758700000000',
  'importe': 3450.00,
});

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late OpenpayService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = OpenpayService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('OpenpayService.crearCargo — antes de salir a la red', () {
    test('sin sesión devuelve Error(errorNoSession)', () async {
      conSesion(null);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(_cuerpoOk(), 200),
      );

      expect((result as Error).msg, AppStrings.errorNoSession);
    });

    test('con el token vacío devuelve Error(errorNoToken)', () async {
      conSesion(
        AuthResponse(
          status: 200,
          msg: 'ok',
          accessToken: '',
          user: TestUser.valid,
          apiVersion: '1.0.0',
          appVersion: '1.0.0',
        ),
      );

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(_cuerpoOk(), 200),
      );

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('con la referencia vacía ni se molesta en llamar', () async {
      conSesion(TestAuthResponse.valid);
      var seLlamo = false;

      final result = await http.runWithClient(
        () => service.crearCargo('   '),
        () => MockClient((_) async {
          seLlamo = true;
          return http.Response(_cuerpoOk(), 200);
        }),
      );

      expect((result as Error).msg, AppStrings.openpaySinReferencia);
      expect(seLlamo, isFalse, reason: 'No hay nada que cobrar');
    });
  });

  group('OpenpayService.crearCargo — la petición', () {
    test('manda la referencia y el Bearer, y NO manda el importe', () async {
      conSesion(TestAuthResponse.valid);
      late http.Request capturada;

      await http.runWithClient(
        () => service.crearCargo('5358A5359A5360'),
        () => MockClient((request) async {
          capturada = request;
          return http.Response(_cuerpoOk(), 200);
        }),
      );

      expect(capturada.method, 'POST');
      expect(capturada.url.path, '/api/v1/openpay/crear-cargo');
      expect(
        capturada.headers['Authorization'],
        'Bearer ${TestAuthResponse.valid.accessToken}',
      );

      final cuerpo = json.decode(capturada.body) as Map<String, dynamic>;
      expect(cuerpo['referencia'], '5358A5359A5360');

      // 🔴 El importe lo calcula el servidor a partir de los cargos que nombra
      // la referencia. Si algún día se mandara desde aquí, una app manipulada
      // podría pedir cobrar un peso por una colegiatura.
      expect(cuerpo.containsKey('importe'), isFalse);
      expect(cuerpo.containsKey('amount'), isFalse);
    });
  });

  group('OpenpayService.crearCargo — respuesta buena', () {
    test('devuelve Success con la URL, el order_id y el importe', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359A5360'),
        () => _responde(_cuerpoOk(), 200),
      );

      final checkout = (result as Success<OpenpayCheckout>).data;
      expect(checkout.url, _urlOpenpay);
      expect(checkout.orderId, '5358A5359A5360-N1758700000000');
      expect(checkout.importe, 3450.00);
    });

    test('acepta el importe como texto, que es como lo serializa PHP', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(
          json.encode({
            'success': true,
            'url': _urlOpenpay,
            'order_id': 'x',
            'importe': '3450.00',
          }),
          200,
        ),
      );

      expect((result as Success<OpenpayCheckout>).data.importe, 3450.00);
    });
  });

  group('OpenpayService.crearCargo — respuesta de rechazo', () {
    // El backend contesta 422, 401, 502 o 503 según qué falló, y en todos los
    // casos con un `message` ya redactado para el tutor. Ese texto se enseña
    // tal cual: es mejor que cualquiera que se invente la app.
    for (final (int codigo, String motivo) in [
      (422, 'Estos cargos ya no están pendientes. Verifica tu estado de cuenta.'),
      (401, 'Tu sesión expiró. Vuelve a entrar para continuar con el pago.'),
      (503, 'El pago con tarjeta no está disponible en este momento.'),
      (502, 'El banco no respondió. Inténtalo de nuevo en unos minutos.'),
    ]) {
      test('un $codigo enseña el mensaje del backend tal cual', () async {
        conSesion(TestAuthResponse.valid);

        final result = await http.runWithClient(
          () => service.crearCargo('5358A5359'),
          () => _responde(
            json.encode({'success': false, 'message': motivo}),
            codigo,
          ),
        );

        expect((result as Error).msg, motivo);
      });
    }

    // Laravel contesta los errores de framework con `{"message": "..."}` y sin
    // `success`, y ese texto es para un programador. Comprobado el 2026-09-24
    // contra arjipagos.moriah.mx, donde la ruta aún no está desplegada:
    // 405 «The POST method is not supported for route api/v1/openpay/…».
    for (final (int codigo, String tecnico) in [
      (
        405,
        'The POST method is not supported for route api/v1/openpay/crear-cargo. '
            'Supported methods: GET, HEAD.',
      ),
      (404, 'Endpoint no encontrado'),
      (500, 'Server Error'),
    ]) {
      test('un $codigo de framework NO enseña su texto técnico', () async {
        conSesion(TestAuthResponse.valid);

        final result = await http.runWithClient(
          () => service.crearCargo('5358A5359'),
          () => _responde(json.encode({'message': tecnico}), codigo),
        );

        final mostrado = (result as Error).msg;
        expect(mostrado, AppStrings.openpayNoSePudoIniciar);
        expect(mostrado, isNot(contains(tecnico)));
        expect(mostrado.toLowerCase(), isNot(contains('route')));
      });
    }

    test('un rechazo sin mensaje cae en el texto genérico', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(json.encode({'success': false}), 422),
      );

      expect((result as Error).msg, AppStrings.openpayNoSePudoIniciar);
    });
  });

  group('OpenpayService.crearCargo — respuestas rotas', () {
    // Sin esto el WebView se abriría en una cadena vacía y el usuario vería una
    // pantalla en blanco sin saber si le cobraron o no.
    test('success:true sin URL se trata como fallo', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(json.encode({'success': true, 'url': ''}), 200),
      );

      expect((result as Error).msg, AppStrings.openpayNoSePudoIniciar);
    });

    test('success:true con URL http se rechaza, no se abre en claro', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde(_cuerpoOk(url: 'http://sandbox-api.openpay.mx/ck/x'), 200),
      );

      expect((result as Error).msg, AppStrings.openpayNoSePudoIniciar);
    });

    test('el HTML de un error 500 no revienta el parseo', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde('<!DOCTYPE html><html><body>Server Error</body></html>', 500),
      );

      expect((result as Error).msg, AppStrings.errorRespuestaInvalida);
    });

    test('un cuerpo que no es JSON devuelve el mensaje de respuesta inválida',
        () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _responde('no soy json', 200),
      );

      expect((result as Error).msg, AppStrings.errorRespuestaInvalida);
    });
  });

  group('OpenpayService.crearCargo — la red', () {
    // Regla del proyecto: nunca `e.toString()` en pantalla. El 2026-08-13 un
    // HandshakeException llegó literal al AlertDialog de login.
    test('un SocketException se traduce a mensaje de conexión', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _lanza(const SocketException('Network is unreachable')),
      );

      final mensaje = (result as Error).msg;
      expect(mensaje, AppStrings.errorConnection);
      expect(mensaje, isNot(contains('SocketException')));
    });

    test('un TimeoutException no enseña el nombre de la excepción', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _lanza(TimeoutException('tardó')),
      );

      expect((result as Error).msg, isNot(contains('TimeoutException')));
    });

    test('un fallo de TLS no enseña el nombre de la excepción', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(
        () => service.crearCargo('5358A5359'),
        () => _lanza(const TlsException('cadena incompleta')),
      );

      expect((result as Error).msg, isNot(contains('TlsException')));
    });
  });
}
