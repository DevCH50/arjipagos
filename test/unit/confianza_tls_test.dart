/// Verifica la raíz que `ConfianzaTls` añade a las autoridades del sistema.
///
/// El 2026-08-27 varios usuarios no podían entrar en la app: su teléfono no
/// tenía la raíz con la que el servidor cerraba su cadena, el handshake fallaba
/// y salía «No se pudo establecer una conexión segura». La app empaqueta ahora
/// **ISRG Root X1** para no depender del almacén de confianza del aparato.
///
/// Lo que se comprueba aquí es que el certificado empaquetado **sirve de
/// verdad**: que es el que se cree que es y que un `SecurityContext` que confía
/// *solo* en él valida la cadena real del servidor. Ese último caso es
/// exactamente la situación del teléfono que fallaba, y es lo único que
/// demuestra que el arreglo funciona.
library;

import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/data/api/ConfianzaTls.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Identidad de ISRG Root X1, la raíz de Let's Encrypt.
  //
  // Se comprueba por los bytes y no por sujeto/emisor porque `dart:io` no
  // expone ningún analizador de X.509: `X509Certificate` solo se obtiene de una
  // conexión real, nunca de un fichero. Comparar el contenido es además más
  // estricto que mirar el nombre, que cualquiera puede repetir.
  //
  // Si alguien sustituye el `.pem` por otro certificado —por error o sin saber
  // para qué está—, estas dos comprobaciones caen.
  const inicioEsperado =
      'MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw';
  const finEsperado = 'm+kXQ99b21/+jh5Xos1AnX5iItreGCc=';
  const bytesDerEsperados = 1391;

  /// Caducidad de ISRG Root X1, tomada del propio certificado con
  /// `openssl x509 -noout -dates`. Es un valor fijo porque las comprobaciones
  /// de arriba garantizan que el fichero es exactamente ese certificado.
  final caducidad = DateTime.utc(2035, 6, 4, 11, 4, 38);

  late Uint8List pem;
  late String cuerpoBase64;

  setUpAll(() async {
    pem =
        (await rootBundle.load(ConfianzaTls.rutaCertificado)).buffer.asUint8List();
    cuerpoBase64 = const LineSplitter()
        .convert(utf8.decode(pem))
        .where((l) => !l.startsWith('-----'))
        .join();
  });

  group('Certificado empaquetado', () {
    test('está empaquetado y tiene forma de PEM', () {
      expect(pem.lengthInBytes, greaterThan(0),
          reason: 'el certificado se resolvió pero llegó vacío');

      final texto = utf8.decode(pem);
      expect(texto, contains('-----BEGIN CERTIFICATE-----'));
      expect(texto, contains('-----END CERTIFICATE-----'));
    });

    test('es ISRG Root X1 y no otro certificado', () {
      expect(cuerpoBase64, startsWith(inicioEsperado));
      expect(cuerpoBase64, endsWith(finEsperado));
      expect(base64.decode(cuerpoBase64).length, equals(bytesDerEsperados));
    });

    test('sigue vigente y con margen de sobra', () {
      final ahora = DateTime.now().toUtc();

      expect(caducidad.isAfter(ahora), isTrue,
          reason: 'el certificado empaquetado ha caducado');
      // Avisa con un año de antelación: sustituirlo exige publicar versión y
      // esperar a que la gente actualice, así que enterarse el día que caduca
      // llega tarde.
      expect(caducidad.isAfter(ahora.add(const Duration(days: 365))), isTrue,
          reason: 'al certificado le queda menos de un año: hay que renovarlo');
    });

    test('construir el SecurityContext con él no lanza', () {
      final contexto = SecurityContext(withTrustedRoots: true);
      // Puede lanzar `TlsException` si la raíz ya estaba en el almacén del
      // sistema; `ConfianzaTls` lo captura a propósito, así que aquí solo se
      // comprueba que no salte ninguna otra cosa.
      try {
        contexto.setTrustedCertificatesBytes(pem);
      } on TlsException {
        // Aceptable: la raíz ya estaba.
      }
    });
  });

  group('Contra el servidor real', () {
    test(
      'un cliente que solo confía en esta raíz completa el handshake',
      () async {
        // `withTrustedRoots: false` es la clave de esta prueba: simula un
        // teléfono cuyo almacén no trae la raíz. Si la cadena que sirve
        // arjipagos.moriah.mx no se pudiera validar SOLO con lo que la app
        // empaqueta, este test fallaría — que es justo el fallo que sufrían
        // los usuarios.
        final contexto = SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificatesBytes(pem);

        // `TestWidgetsFlutterBinding` instala un `HttpOverrides` que corta toda
        // la red y responde 400 a cualquier petición. Aquí hace falta una
        // conexión de verdad —es lo único que prueba que la cadena valida—, así
        // que se aparta durante el test y se repone al terminar. El binding
        // sigue haciendo falta para `rootBundle`, de ahí no quitarlo entero.
        final overridesDelBinding = HttpOverrides.current;
        HttpOverrides.global = null;

        final cliente = HttpClient(context: contexto);
        try {
          final peticion =
              await cliente.getUrl(Uri.https('arjipagos.moriah.mx', '/'));
          final respuesta = await peticion.close();
          await respuesta.drain<void>();

          expect(respuesta.certificate, isNotNull,
              reason: 'la conexión debía ser TLS');
        } finally {
          cliente.close(force: true);
          HttpOverrides.global = overridesDelBinding;
        }
      },
      // Necesita salir a Internet: excluible con
      // `flutter test --exclude-tags red`.
      tags: ['red'],
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
