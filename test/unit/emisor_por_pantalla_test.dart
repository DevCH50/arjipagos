/// Test guardián del cableado emisor ↔ pantalla.
///
/// **El contrato:** "Pagos Pendientes" cobra con `emisorfiscal_id = 1` y "Otros
/// pagos" con `emisorfiscal_id = 2`. Cada emisor es un contrato distinto de
/// Adquira, con su propia cuenta bancaria; equivocarse aquí manda el dinero a la
/// cuenta que no es.
///
/// **Por qué se comprueba sobre el código fuente y no montando la app:** el
/// número solo aparece una vez, en el `routes:` de `lib/main.dart`, y de ahí
/// baja por `EdoCtaPage` → `CarritoBloc` → `PagoRequest`. Ese primer eslabón no
/// se puede afirmar desde un test de widget sin arrancar el `MaterialApp`
/// entero con su inyección de dependencias. Un `sed` distraído en `main.dart`
/// pasaría desapercibido: el resto de la cadena seguiría funcionando, solo que
/// cobrando por el contrato equivocado, sin error ni aviso.
///
/// Que el número llegue al mapa que se manda a Adquira lo cubre
/// `test/unit/models/pago_request_test.dart`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String main_;

  setUpAll(() {
    main_ = File('lib/main.dart').readAsStringSync();
  });

  test('la ruta "edo_cta_otros" monta EdoCtaPage con emisorFiscalId 2', () {
    // La ruta y el 2 tienen que estar en el mismo bloque: basta con que alguien
    // reordene las rutas para que un `contains('emisorFiscalId: 2')` suelto deje
    // de significar nada.
    final bloque = RegExp(
      r"'edo_cta_otros'\s*:.*?EdoCtaPage\s*\(\s*emisorFiscalId\s*:\s*(\d+)",
      dotAll: true,
    ).firstMatch(main_);

    expect(
      bloque,
      isNotNull,
      reason:
          'la ruta edo_cta_otros ya no monta EdoCtaPage con un '
          'emisorFiscalId explícito',
    );
    expect(
      bloque!.group(1),
      equals('2'),
      reason: '"Otros pagos" cobraría por el contrato equivocado',
    );
  });

  test(
    'la ruta "edo_cta" NO fija emisor, para quedarse en el predeterminado 1',
    () {
      // "Pagos Pendientes" no pasa el parámetro: toma el valor por omisión de
      // `EdoCtaPage`, que es `kEmisorFiscalPredeterminado`. Si algún día se
      // quisiera explícito, hay que cambiar este test a propósito.
      final bloque = RegExp(
        r"'edo_cta'\s*:\s*\(BuildContext context\)\s*=>\s*const EdoCtaPage\(\)",
      );

      expect(
        bloque.hasMatch(main_),
        isTrue,
        reason: 'la ruta edo_cta dejó de usar el emisor predeterminado',
      );
    },
  );

  test('el emisor predeterminado sigue siendo 1', () {
    final fuente = File(
      'lib/src/domain/models/EstadoDeCuenta.dart',
    ).readAsStringSync();

    final valor = RegExp(
      r'kEmisorFiscalPredeterminado\s*=\s*(\d+)',
    ).firstMatch(fuente)?.group(1);

    expect(
      valor,
      equals('1'),
      reason: '"Pagos Pendientes" depende de este valor por omisión',
    );
  });
}
