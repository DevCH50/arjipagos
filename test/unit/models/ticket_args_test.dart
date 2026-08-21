/// Tests para TicketArgs.
///
/// Es el contrato de la ruta restaurable del ticket: el sistema operativo solo
/// guarda tipos primitivos, así que los argumentos viajan como mapa. Si esta
/// ida y vuelta se rompe, al regresar de compartir el PDF la pantalla se
/// quedaría sin URL y el usuario vería "ticket no disponible".
library;

import 'package:arjipagos/src/presentation/pages/ticket/TicketPage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketArgs', () {
    const url = 'https://arjipagos.moriah.mx/api/v1/tickets/abc-123/print';

    test('aMapa y desdeRuta son inversas', () {
      const original = TicketArgs(url: url, folio: 'T7719');

      final recuperado = TicketArgs.desdeRuta(original.aMapa());

      expect(recuperado.url, url);
      expect(recuperado.folio, 'T7719');
    });

    test('el mapa solo lleva tipos primitivos', () {
      const args = TicketArgs(url: url, folio: 'T7719');

      final mapa = args.aMapa();

      // El tipo del mapa ya obliga a String; la aserción fija el contenido
      // exacto que el sistema tendrá que guardar y devolver.
      expect(mapa, {'url': url, 'folio': 'T7719'});
    });

    test('el folio es opcional', () {
      const args = TicketArgs(url: url);

      expect(args.folio, '');
      expect(TicketArgs.desdeRuta(args.aMapa()).folio, '');
    });

    test('tolera que la ruta no traiga argumentos', () {
      final args = TicketArgs.desdeRuta(null);

      expect(args.url, '');
      expect(args.folio, '');
    });

    test('tolera un mapa incompleto o con valores nulos', () {
      final args = TicketArgs.desdeRuta(<String, Object?>{'url': null});

      expect(args.url, '');
      expect(args.folio, '');
    });

    test('ignora un tipo inesperado en vez de reventar', () {
      final args = TicketArgs.desdeRuta('no soy un mapa');

      expect(args.url, '');
    });
  });
}
