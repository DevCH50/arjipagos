/// Tests de la tabla de contratos con Adquira.
///
/// Lo que se protege aquí no es una pantalla: es a qué cuenta bancaria entra el
/// dinero. Un `idexpress` equivocado no produce ningún error —Adquira acepta la
/// operación— y el cobro aparece en la cuenta del otro emisor.
library;

import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfiguracionAdquira.para', () {
    test('el emisor 1 devuelve la configuración del contrato 1', () {
      expect(ConfiguracionAdquira.para(1), same(ConfiguracionAdquira.ef1));
    });

    test('el emisor 2 devuelve la configuración del contrato 2', () {
      expect(ConfiguracionAdquira.para(2), same(ConfiguracionAdquira.ef2));
    });

    test('un emisor desconocido cae en el contrato 1 en vez de reventar', () {
      // Preferimos cobrar en la cuenta principal —donde el dinero se puede
      // reasignar— a dejar al usuario sin poder pagar.
      expect(ConfiguracionAdquira.para(99), same(ConfiguracionAdquira.ef1));
      expect(ConfiguracionAdquira.conoce(99), isFalse);
    });

    test('conoce() distingue los emisores con contrato propio', () {
      expect(ConfiguracionAdquira.conoce(1), isTrue);
      expect(ConfiguracionAdquira.conoce(2), isTrue);
      expect(ConfiguracionAdquira.emisoresConocidos, equals([1, 2]));
    });
  });

  group('ConfiguracionAdquira — contrato 1 (producción)', () {
    test('conserva exactamente los parámetros que la app venía enviando', () {
      // Estos valores estaban cableados en `PagoRequest` cuando había un solo
      // endpoint. Si alguno cambia sin querer, los pagos del emisor 1 —que es
      // el grueso— empiezan a fallar o a cobrarse mal.
      const ef1 = ConfiguracionAdquira.ef1;
      expect(
        ef1.endpoint,
        equals('https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado'),
      );
      expect(ef1.idExpress, equals('928'));
      expect(ef1.financiamiento, equals('0'));
      expect(ef1.moneda, equals('MXN'));
      expect(ef1.tipo, equals('1'));
      expect(ef1.tipoPago, equals('1'));
      expect(ef1.plazos, equals(''));
      expect(ef1.mediosPago, equals('111000'));
    });

    test('no está marcado como provisional', () {
      expect(ConfiguracionAdquira.ef1.esProvisional, isFalse);
    });
  });

  group('ConfiguracionAdquira — contrato 2 (PROVISIONAL)', () {
    test(
      'sigue marcado como provisional mientras use datos prestados del 1',
      () {
        // ⚠️ Este test es un aviso, no un fallo de diseño.
        //
        // Hoy el contrato 2 lleva los datos del 1 a propósito, para poder
        // montar "Otros pagos" mientras llegan los reales. Eso significa que
        // TODO lo que se cobre en esa pantalla entra en la cuenta bancaria del
        // emisor 1.
        //
        // Cuando lleguen los datos del contrato 2: cambiar `endpoint` e
        // `idExpress` en `ConfiguracionAdquira.ef2`, quitar `esProvisional` y
        // BORRAR este grupo de tests entero.
        expect(
          ConfiguracionAdquira.ef2.esProvisional,
          isTrue,
          reason: 'Si ya no es provisional, actualiza este test y publica.',
        );
      },
    );

    test(
      'mientras sea provisional, sus datos son idénticos a los del contrato 1',
      () {
        // Cazador de incoherencias: si alguien cambia el endpoint del 2 pero
        // olvida quitar `esProvisional` —o al revés—, la configuración queda a
        // medias y este test lo detiene antes de que llegue a cobrar.
        const ef1 = ConfiguracionAdquira.ef1;
        const ef2 = ConfiguracionAdquira.ef2;

        expect(ef2.endpoint, equals(ef1.endpoint));
        expect(ef2.idExpress, equals(ef1.idExpress));
        expect(ef2.financiamiento, equals(ef1.financiamiento));
        expect(ef2.moneda, equals(ef1.moneda));
        expect(ef2.tipo, equals(ef1.tipo));
        expect(ef2.tipoPago, equals(ef1.tipoPago));
        expect(ef2.plazos, equals(ef1.plazos));
        expect(ef2.mediosPago, equals(ef1.mediosPago));
      },
    );

    test('aun provisional, se distingue del 1 en los registros', () {
      // La descripción es lo único que permite ver en el log cuál de los dos
      // contratos se usó, ya que los parámetros coinciden.
      expect(
        ConfiguracionAdquira.ef2.descripcion,
        isNot(equals(ConfiguracionAdquira.ef1.descripcion)),
      );
    });
  });

  group('Emisor predeterminado', () {
    test('es el 1, para que un backend antiguo se comporte igual que antes', () {
      // Mientras el backend no mande `emisorfiscal_id` por pago, todo cae en el
      // emisor 1, que es exactamente lo que la app hacía con un solo endpoint.
      expect(kEmisorFiscalPredeterminado, equals(1));
      expect(
        ConfiguracionAdquira.emisorFiscalPredeterminado,
        equals(kEmisorFiscalPredeterminado),
      );
    });
  });
}
