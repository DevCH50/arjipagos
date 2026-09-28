import 'dart:io';

import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/pago_webview_cuerpo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Test guardián: el JSON del retorno no se le enseña al padre.
///
/// Origen: prueba del cobro por OpenPay en el Oppo, el 2026-09-28. Al pulsar
/// «Finalizar», el WebView aterriza en nuestro retorno, que responde
/// `{"success":true,"message":"…"}` sin ningún estilo. El diálogo de «Pago
/// exitoso» salía encima, y detrás se leía el JSON en crudo con la barra de
/// «Impresión con formato estilístico» de Chrome.
///
/// Lo tapa una capa opaca del color del tema, que pinta `PagoWebViewCuerpo`.
/// Ese widget se monta de verdad con un WebView falso. Cuándo se activa y
/// cuándo se quita lo decide `PagoWebViewPage`, que no se puede montar sin la
/// vista nativa, y eso se comprueba sobre su código fuente.
void main() {
  setUpAll(() => WebViewPlatform.instance = _FakeWebViewPlatform());

  /// Busca la capa: un `ColoredBox` que llena el `Stack` por completo.
  Finder capa() => find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(ColoredBox),
      );

  Future<void> montar(
    WidgetTester tester, {
    required bool respuestaRecibida,
    ThemeData? tema,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: Scaffold(
          body: PagoWebViewCuerpo(
            controller: WebViewController(),
            errorMessage: null,
            cargando: false,
            respuestaRecibida: respuestaRecibida,
            onReintentar: () {},
          ),
        ),
      ),
    );
  }

  group('PagoWebViewCuerpo', () {
    testWidgets('sin respuesta, la pasarela se ve sin nada encima',
        (tester) async {
      await montar(tester, respuestaRecibida: false);

      expect(find.byType(WebViewWidget), findsOneWidget);
      expect(capa(), findsNothing);
    });

    for (final brillo in Brightness.values) {
      testWidgets('con respuesta, una capa opaca tapa el WebView ($brillo)',
          (tester) async {
        final tema = ThemeData(brightness: brillo);
        await montar(tester, respuestaRecibida: true, tema: tema);

        final ColoredBox caja = tester.widget(capa());
        expect(caja.color, tema.scaffoldBackgroundColor);
        expect(caja.color.a, 1.0, reason: 'con transparencia se leería');
        // Ocupa lo mismo que el WebView: lo tapa entero.
        expect(
          tester.getRect(capa()),
          tester.getRect(find.byType(WebViewWidget)),
        );
      });
    }
  });

  group('PagoWebViewPage', () {
    final String fuente = File(
      'lib/src/presentation/pages/pago_webview/PagoWebViewPage.dart',
    ).readAsStringSync();

    test('activa la capa justo al procesar la respuesta', () {
      final int marca = fuente.indexOf('_pagoProcessed = true;');
      expect(marca, isNonNegative);
      expect(fuente.indexOf('_respuestaRecibida = true'), greaterThan(marca));
      expect(fuente, contains('respuestaRecibida: _respuestaRecibida'));
    });

    test('al reintentar la quita para volver a ver la pasarela', () {
      final int inicio = fuente.indexOf('void _recargarWebView()');
      final int fin = fuente.indexOf('void _procesarJsonRespuesta');
      expect(
        fuente.substring(inicio, fin),
        contains('_respuestaRecibida = false'),
      );
    });
  });
}

/// Plataforma de WebView falsa: el widget no pinta nada nativo.
class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) =>
      _FakePlatformWebViewWidget(params);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) =>
      _FakePlatformWebViewController(params);
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();
}
