/// Tests de cómo se abre cada pasarela en el WebView.
///
/// Aquí se decide **qué se le manda a un tercero**, así que es lo que más
/// conviene tener blindado de toda la integración de OpenPay:
///
/// - Adquira (emisor 1) sigue yendo por **POST** con su formulario y su
///   `Authorization`, exactamente como antes.
/// - OpenPay (emisor 2) va por **GET** y **sin ni una cabecera**. Mandarle el
///   `Bearer` del tutor a un dominio de OpenPay sería entregarle a un tercero
///   la credencial con la que se lee su estado de cuenta y sus facturas.
/// - Solo OpenPay recibe el `viewport` móvil: sin él, el 3D Secure salía
///   diminuto en el iPhone. Adquira no cambia.
library;

import 'dart:convert';

import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/peticion_webview.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/webview_scripts.dart';
import 'package:flutter_test/flutter_test.dart';

const String _token = 'token-secreto-del-tutor';

PagoWebViewArgs _args({
  required String url,
  required Map<String, String> params,
  int emisorFiscalId = 1,
}) => PagoWebViewArgs(
  url: url,
  params: params,
  token: _token,
  emisorFiscalId: emisorFiscalId,
);

void main() {
  group('Adquira — con parámetros, POST (el camino de siempre)', () {
    final peticion = PeticionWebView.desde(
      _args(
        url: 'https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado',
        params: const {
          'importe': '2000.00',
          'referencia': '5358A5359',
          'idexpress': '928',
        },
      ),
    );

    test('va por POST', () {
      expect(peticion.esPost, isTrue);
    });

    test('NO ajusta el viewport: Adquira se queda como estaba', () {
      expect(peticion.ajustaViewport, isFalse);
    });

    test('manda el formulario codificado', () {
      expect(peticion.body, isNotNull);
      final cuerpo = utf8.decode(peticion.body!);
      expect(cuerpo, contains('importe=2000.00'));
      expect(cuerpo, contains('referencia=5358A5359'));
      expect(cuerpo, contains('idexpress=928'));
    });

    test('manda el Content-Type de formulario y el Bearer', () {
      expect(
        peticion.headers['Content-Type'],
        'application/x-www-form-urlencoded',
      );
      expect(peticion.headers['Authorization'], 'Bearer $_token');
    });

    test('escapa los valores con caracteres especiales', () {
      final p = PeticionWebView.desde(
        _args(
          url: 'https://x.mx',
          params: const {'descripcion': 'COLEGIATURA 26 / 27 & extras'},
        ),
      );

      final cuerpo = utf8.decode(p.body!);
      expect(cuerpo, isNot(contains(' ')));
      expect(cuerpo, contains('%2F')); // la barra
      expect(cuerpo, contains('%26')); // el ampersand
    });
  });

  group('OpenPay — sin parámetros, GET y sin cabeceras', () {
    final peticion = PeticionWebView.desde(
      _args(
        url: 'https://sandbox-api.openpay.mx/ck/Cb0EJHFIp2aG',
        params: const {},
        emisorFiscalId: 2,
      ),
    );

    test('va por GET', () {
      expect(peticion.esPost, isFalse);
    });

    test('ajusta el viewport: en iPhone el 3D Secure salía diminuto', () {
      expect(peticion.ajustaViewport, isTrue);
    });

    test('no lleva cuerpo', () {
      expect(peticion.body, isNull);
    });

    // 🔴 EL TEST QUE IMPORTA. Si esto se rompe, el token de la sesión del
    // tutor se le está mandando a OpenPay en cada cobro.
    test('NO lleva ninguna cabecera, y menos el Bearer', () {
      expect(peticion.headers, isEmpty);
      expect(peticion.headers.containsKey('Authorization'), isFalse);
    });

    test('el token no aparece por ningún lado de la petición', () {
      final todo = '${peticion.headers}${peticion.body}';
      expect(todo, isNot(contains(_token)));
      expect(todo.toLowerCase(), isNot(contains('bearer')));
    });
  });

  group('El viewport que se inyecta en OpenPay', () {
    const script = WebViewScripts.viewportMovil;

    test('respeta el viewport que ya traiga la página (la del banco)', () {
      expect(script, contains('meta[name="viewport"]'));
      expect(script, contains('return;'));
    });

    test('pinta al ancho del aparato y sin zoom inicial', () {
      expect(script, contains('width=device-width, initial-scale=1'));
    });

    test('no bloquea el pellizco para ampliar', () {
      expect(script, isNot(contains('user-scalable')));
      expect(script, isNot(contains('maximum-scale')));
    });
  });
}
