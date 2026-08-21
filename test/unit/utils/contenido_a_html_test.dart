/// Tests unitarios para contenidoAHtml.
///
/// El caso crítico es el de los saltos `\r\n`: el backend los manda así y el
/// parser de Markdown espera `\n`. Con el `\r` de sobra deja de reconocer
/// listas y encabezados, y la nota se vería como un párrafo con guiones y
/// almohadillas sueltas.
library;

import 'package:arjipagos/src/core/utils/contenido_a_html.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('contenidoAHtml — markdown', () {
    test('convierte negritas', () {
      final html = contenidoAHtml('El **25 de septiembre**', BannerFormato.markdown);

      expect(html, contains('<strong>25 de septiembre</strong>'));
    });

    test('convierte encabezados', () {
      final html =
          contenidoAHtml('### Qué necesita saber', BannerFormato.markdown);

      expect(html, contains('<h3'));
      expect(html, contains('Qué necesita saber'));
    });

    test('convierte listas con viñetas', () {
      final html =
          contenidoAHtml('- Primero\n- Segundo', BannerFormato.markdown);

      expect(html, contains('<ul>'));
      expect(html, contains('<li>Primero</li>'));
    });

    test('reconoce el formato aunque los saltos vengan como \\r\\n', () {
      // Tal cual lo manda el backend.
      const cuerpo = '### Título\r\n\r\n- Uno\r\n- Dos';

      final html = contenidoAHtml(cuerpo, BannerFormato.markdown);

      expect(html, contains('<h3'));
      expect(html, contains('<ul>'));
      expect(html, contains('<li>Uno</li>'));
    });

    test('caso real completo del endpoint', () {
      final cuerpo = TestBanner.anualidadJson['cuerpo'] as String;

      final html = contenidoAHtml(cuerpo, BannerFormato.markdown);

      expect(html, contains('<strong>25 de septiembre</strong>'));
      expect(html, contains('<h3'));
      expect(html, contains('<li>'));
      // Ningún resto de la sintaxis Markdown debe quedar visible.
      expect(html, isNot(contains('**')));
      expect(html, isNot(contains('###')));
    });
  });

  group('contenidoAHtml — otros formatos', () {
    test('el HTML pasa tal cual, sin reprocesarse', () {
      const cuerpo = '<p>Ya viene en <b>HTML</b></p>';

      expect(contenidoAHtml(cuerpo, BannerFormato.html), cuerpo);
    });

    test('el texto plano se escapa para no interpretarse como etiquetas', () {
      final html = contenidoAHtml('Descuento <30%> & más', BannerFormato.texto);

      expect(html, contains('&lt;30%&gt;'));
      expect(html, contains('&amp;'));
    });

    test('el texto plano conserva los saltos de línea', () {
      final html = contenidoAHtml('Primera\nSegunda', BannerFormato.texto);

      expect(html, contains('<br>'));
    });

    test('un cuerpo vacío devuelve cadena vacía en cualquier formato', () {
      for (final formato in BannerFormato.values) {
        expect(contenidoAHtml('', formato), '');
      }
    });
  });
}
