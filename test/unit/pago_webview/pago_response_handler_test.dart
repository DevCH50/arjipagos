/// Tests unitarios para PagoResponseHandler.
///
/// Es el núcleo de decisión del flujo de pago en el WebView: interpreta la
/// respuesta (JSON del canal JS o texto legacy) para decidir éxito/fallo.
/// La página `PagoWebViewPage` no se monta en `flutter test` porque
/// `WebViewController` requiere la platform view real (webview_flutter);
/// su API queda cubierta por `flutter analyze` en tiempo de compilación.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/pago_response_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PagoResponseHandler.procesarJson', () {
    test('detecta pago exitoso con success:true', () {
      final r = PagoResponseHandler.procesarJson(
          '{"success": true, "message": "Pago aplicado"}');

      expect(r.processed, true);
      expect(r.success, true);
      expect(r.message, 'Pago aplicado');
    });

    test('detecta pago fallido con success:false y conserva el mensaje', () {
      final r = PagoResponseHandler.procesarJson(
          '{"success": false, "message": "Tarjeta rechazada"}');

      expect(r.processed, true);
      expect(r.success, false);
      expect(r.message, 'Tarjeta rechazada');
    });

    test('usa mensaje por defecto cuando falla sin message', () {
      final r = PagoResponseHandler.procesarJson('{"success": false}');

      expect(r.success, false);
      expect(r.message, AppStrings.pagoNoProcesado);
    });

    test('cae a detección legacy cuando el string no es JSON válido', () {
      final r = PagoResponseHandler.procesarJson('pago aprobado por el banco');

      expect(r.processed, true);
      expect(r.success, true);
    });
  });

  group('PagoResponseHandler.procesarLegacy', () {
    test('reconoce palabras clave de éxito', () {
      for (final texto in ['SUCCESS', 'pago exitoso', 'Aprobado']) {
        final r = PagoResponseHandler.procesarLegacy(texto);
        expect(r.success, true, reason: 'para "$texto"');
        expect(r.processed, true);
      }
    });

    test('reconoce palabras clave de error', () {
      for (final texto in ['error 500', 'pago fallido', 'Rechazado']) {
        final r = PagoResponseHandler.procesarLegacy(texto);
        expect(r.success, false, reason: 'para "$texto"');
        expect(r.processed, true);
      }
    });

    test('retorna notProcessed cuando no hay palabras clave', () {
      final r = PagoResponseHandler.procesarLegacy('texto neutro sin señales');

      expect(r.processed, false);
      expect(r, PagoResult.notProcessed);
    });
  });
}
