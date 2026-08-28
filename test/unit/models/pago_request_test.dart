/// Tests de [PagoRequest], con foco en `emisorfiscal_id`.
///
/// **Lo que fijan:** "Pagos Pendientes" cobra con `emisorfiscal_id = 1` y
/// "Otros pagos" con `emisorfiscal_id = 2`, y ese número sale de verdad en el
/// mapa que se manda a Adquira.
///
/// **Por qué importa que esté en el `toMap()` y no solo en el modelo:** hasta el
/// 2026-08-28 el campo existía en la clase pero no viajaba —el `toMap()` lo
/// omitía—, así que del lado del cobro no había forma de saber de qué contrato
/// venía. Y no se puede deducir del `idexpress`: mientras el contrato 2 use los
/// datos prestados del 1, **los dos mandan el mismo `idexpress` ('928')**, de
/// modo que este campo es lo único que los distingue.
library;

import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye el request tal como lo arma `CarritoBloc`: los parámetros de
/// comercio salen de `ConfiguracionAdquira.para(emisor)`, nunca a mano.
PagoRequest requestPara(int emisorFiscalId) {
  final configuracion = ConfiguracionAdquira.para(emisorFiscalId);

  return PagoRequest(
    token: 'token-de-prueba',
    userId: 1304,
    importe: 2450.5,
    urlRetorno: 'https://arjipagos.moriah.mx/retorno',
    referencia: 'REF-1',
    emisorFiscalId: emisorFiscalId,
    idExpress: configuracion.idExpress,
    financiamiento: configuracion.financiamiento,
    moneda: configuracion.moneda,
    tipo: configuracion.tipo,
    tipoPago: configuracion.tipoPago,
    plazos: configuracion.plazos,
    mediosPago: configuracion.mediosPago,
  );
}

void main() {
  group('PagoRequest.toMap — emisorfiscal_id', () {
    test('"Pagos Pendientes" manda emisorfiscal_id = 1', () {
      expect(requestPara(1).toMap()['emisorfiscal_id'], equals('1'));
    });

    test('"Otros pagos" manda emisorfiscal_id = 2', () {
      expect(requestPara(2).toMap()['emisorfiscal_id'], equals('2'));
    });

    test('viaja siempre, no solo cuando es distinto del predeterminado', () {
      // Un `if (emisor != 1)` dejaría fuera al emisor 1, que es el grueso de los
      // cobros. La clave está presente en los dos casos.
      expect(requestPara(1).toMap().containsKey('emisorfiscal_id'), isTrue);
      expect(requestPara(2).toMap().containsKey('emisorfiscal_id'), isTrue);
    });

    test('va como texto, como el resto del mapa', () {
      // `toMap()` devuelve `Map<String, String>` porque se manda como form-data.
      expect(requestPara(2).toMap()['emisorfiscal_id'], isA<String>());
    });

    test('los dos emisores se distinguen SOLO por este campo mientras el 2 sea '
        'provisional', () {
      // Este test es el que explica por qué el campo hace falta. El día que
      // llegue el contrato real del emisor 2, los `idexpress` dejarán de
      // coincidir y este test caerá: entonces hay que actualizarlo, no borrarlo.
      final uno = requestPara(1).toMap();
      final dos = requestPara(2).toMap();

      expect(
        ConfiguracionAdquira.ef2.esProvisional,
        isTrue,
        reason: 'si el contrato 2 ya es real, revisa este test',
      );
      expect(dos['idexpress'], equals(uno['idexpress']));
      expect(dos['emisorfiscal_id'], isNot(equals(uno['emisorfiscal_id'])));
    });
  });

  group('PagoRequest.toMap — el resto de parámetros', () {
    test('el importe va con dos decimales', () {
      expect(requestPara(1).toMap()['importe'], equals('2450.50'));
    });

    test('lleva los parámetros de comercio de su contrato', () {
      final mapa = requestPara(1).toMap();

      expect(mapa['idexpress'], equals(ConfiguracionAdquira.ef1.idExpress));
      expect(mapa['moneda'], equals(ConfiguracionAdquira.ef1.moneda));
      expect(mapa['mediospago'], equals(ConfiguracionAdquira.ef1.mediosPago));
    });

    test('el token NO viaja en el mapa', () {
      // El mapa se vuelca en un formulario que se manda a Adquira; el token de
      // sesión de la app no pinta nada ahí.
      expect(requestPara(1).toMap().containsKey('token'), isFalse);
    });
  });
}
