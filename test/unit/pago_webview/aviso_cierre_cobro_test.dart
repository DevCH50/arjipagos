/// Tests de la tabla «estado del cobro → aviso» de OpenPay.
///
/// Fija lo acordado con el backend el 2026-09-28, y sobre todo lo que evita
/// un pago doble: que «sin confirmar» vacíe el carrito y que ningún estado
/// dudoso se lea como «no pagaste».
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoCobroOpenpay.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/aviso_cierre_cobro.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvisoCierreCobro.para', () {
    test('pagado no tiene aviso: usa el diálogo de éxito de siempre', () {
      expect(
        AvisoCierreCobro.para(const EstadoCobroOpenpay(EstadoCobro.pagado)),
        isNull,
      );
    });

    test('rechazado: error con el motivo del backend, carrito intacto', () {
      final aviso = AvisoCierreCobro.para(
        const EstadoCobroOpenpay(
          EstadoCobro.rechazado,
          mensaje: 'Fondos insuficientes',
        ),
      )!;

      expect(aviso.tipo, TipoAvisoCierre.rechazo);
      expect(aviso.titulo, AppStrings.openpayRechazadoTitle);
      expect(aviso.mensaje, 'Fondos insuficientes');
      expect(aviso.vaciarCarrito, isFalse);
    });

    test('rechazado sin motivo: el texto propio', () {
      final aviso = AvisoCierreCobro.para(
        const EstadoCobroOpenpay(EstadoCobro.rechazado),
      )!;

      expect(aviso.mensaje, AppStrings.openpayRechazadoMsg);
    });

    test('pendiente: informativo, texto propio, carrito intacto', () {
      final aviso = AvisoCierreCobro.para(
        const EstadoCobroOpenpay(
          EstadoCobro.pendiente,
          mensaje: 'El pago no se completó.',
        ),
      )!;

      expect(aviso.tipo, TipoAvisoCierre.informativo);
      expect(aviso.titulo, AppStrings.openpayNoCompletadoTitle);
      // El propio dice además que los pagos siguen en el carrito.
      expect(aviso.mensaje, AppStrings.openpayNoCompletadoMsg);
      expect(aviso.vaciarCarrito, isFalse);
    });

    test('sin confirmar: advertencia, mensaje del backend y VACÍA el carrito', () {
      final aviso = AvisoCierreCobro.para(
        const EstadoCobroOpenpay.sinConfirmar(
          mensaje: 'NO vuelvas a pagar; revisa en unos minutos.',
        ),
      )!;

      expect(aviso.tipo, TipoAvisoCierre.advertencia);
      expect(aviso.titulo, AppStrings.openpaySinConfirmarTitle);
      expect(aviso.mensaje, 'NO vuelvas a pagar; revisa en unos minutos.');
      expect(aviso.vaciarCarrito, isTrue);
    });

    test('sin confirmar y sin mensaje: el propio también dice no pagar', () {
      final aviso = AvisoCierreCobro.para(
        const EstadoCobroOpenpay.sinConfirmar(),
      )!;

      expect(aviso.mensaje, AppStrings.openpaySinConfirmarMsg);
      expect(aviso.mensaje, contains('NO vuelvas a pagar'));
    });
  });

  group('EstadoCobroOpenpay.desdeJson', () {
    test('sin la clave `estado` no se cree: sin confirmar y sin mensaje', () {
      final estado = EstadoCobroOpenpay.desdeJson({
        'message': 'The GET method is not supported for route…',
      });

      expect(estado.estado, EstadoCobro.sinConfirmar);
      expect(estado.mensaje, isEmpty);
    });

    test('tolera mayúsculas y espacios en el estado', () {
      final estado = EstadoCobroOpenpay.desdeJson({
        'estado': ' PAGADO ',
        'message': '  ok  ',
      });

      expect(estado.estado, EstadoCobro.pagado);
      expect(estado.mensaje, 'ok');
    });
  });

  group('PagoWebViewArgs.verificaAlCerrar', () {
    PagoWebViewArgs args(String? orderId) => PagoWebViewArgs(
      url: 'https://x',
      params: const {},
      token: 't',
      emisorFiscalId: 2,
      orderId: orderId,
    );

    test('con order_id (OpenPay) sí', () {
      expect(args('ref-N1').verificaAlCerrar, isTrue);
    });

    test('sin order_id (Adquira), o vacío, no: se cierra como siempre', () {
      expect(args(null).verificaAlCerrar, isFalse);
      expect(args('').verificaAlCerrar, isFalse);
    });
  });
}
