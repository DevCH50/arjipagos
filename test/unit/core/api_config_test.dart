/// Tests unitarios para ApiConfig.repararUrlDelBackend.
///
/// Blindan el arreglo de las URLs absolutas que el backend arma con `localhost`
/// —el `ticket_url` de los pagos realizados es la primera—. Ese host solo
/// resuelve dentro de la PC que corre el servidor: desde el emulador de Android
/// y desde cualquier teléfono físico, Android o iPhone, la descarga fallaría.
///
/// Igual de importante es lo contrario: una URL con host real debe salir
/// intacta, para que la app nunca redirija una petición a otro servidor.
library;

import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig.repararUrlDelBackend', () {
    test('cambia el host localhost por el configurado, conservando la ruta',
        () {
      const url =
          'http://localhost:8000/api/v1/tickets/a7064b3b-a517/print';

      final reparada = Uri.parse(ApiConfig.repararUrlDelBackend(url));

      expect(reparada.host, ApiConfig.baseUrl.split(':').first);
      expect(reparada.path, '/api/v1/tickets/a7064b3b-a517/print');
    });

    test('repara también 127.0.0.1 y 0.0.0.0', () {
      for (final host in ['127.0.0.1:8000', '0.0.0.0:8000']) {
        final reparada =
            Uri.parse(ApiConfig.repararUrlDelBackend('http://$host/api/v1/x'));

        expect(reparada.host, isNot('127.0.0.1'));
        expect(reparada.host, isNot('0.0.0.0'));
        expect(reparada.path, '/api/v1/x');
      }
    });

    test('conserva el query string al reparar', () {
      const url = 'http://localhost:8000/api/v1/tickets/print?formato=pdf';

      final reparada = Uri.parse(ApiConfig.repararUrlDelBackend(url));

      expect(reparada.queryParameters['formato'], 'pdf');
    });

    test('deja intacta una URL con host real (producción)', () {
      const url =
          'https://arjipagos.moriah.mx/api/v1/tickets/a7064b3b-a517/print';

      expect(ApiConfig.repararUrlDelBackend(url), url);
    });

    test('no redirige una URL de un tercero a nuestro servidor', () {
      const url = 'https://www.adquiramexico.com.mx/mExpress/pago/avanzado';

      expect(ApiConfig.repararUrlDelBackend(url), url);
    });

    test('devuelve la cadena vacía tal cual', () {
      expect(ApiConfig.repararUrlDelBackend(''), '');
    });

    test('devuelve sin cambios lo que no es una URL absoluta', () {
      expect(ApiConfig.repararUrlDelBackend('no-es-una-url'), 'no-es-una-url');
    });

    test('usa https cuando la app apunta a producción', () {
      final reparada =
          Uri.parse(ApiConfig.repararUrlDelBackend('http://localhost:8000/x'));

      expect(reparada.scheme, ApiConfig.useHttps ? 'https' : 'http');
    });
  });
}
