/// Tests unitarios para la función stripHtml() de html_utils.dart.
///
/// Verifica:
/// - Eliminación de etiquetas HTML simples y de bloque.
/// - Decodificación de entidades numéricas (decimales y hexadecimales).
/// - Decodificación de entidades nombradas comunes y caracteres en español.
/// - Normalización de espacios y manejo de cadenas vacías/nulas.
library;

import 'package:arjipagos/src/core/utils/html_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stripHtml', () {
    // -------------------------------------------------------------------------
    // Casos base
    // -------------------------------------------------------------------------
    group('casos base', () {
      test('cadena vacía retorna cadena vacía', () {
        expect(stripHtml(''), equals(''));
      });

      test('texto sin HTML retorna el mismo texto', () {
        expect(stripHtml('Hola mundo'), equals('Hola mundo'));
      });

      test('solo espacios se comprimen a un espacio', () {
        expect(stripHtml('   '), equals(''));
      });
    });

    // -------------------------------------------------------------------------
    // Eliminación de etiquetas
    // -------------------------------------------------------------------------
    group('eliminación de etiquetas', () {
      test('elimina etiqueta simple', () {
        expect(stripHtml('<b>Texto</b>'), equals('Texto'));
      });

      test('elimina etiquetas h3', () {
        expect(
          stripHtml('<h3>Tu estado de cuenta ha vencido</h3>'),
          equals('Tu estado de cuenta ha vencido'),
        );
      });

      test('elimina múltiples etiquetas anidadas', () {
        expect(
          stripHtml('<div><p><b>Texto</b></p></div>'),
          equals('Texto'),
        );
      });

      test('elimina etiquetas con atributos de estilo', () {
        expect(
          stripHtml('<p style="color:red;font-size:14px;">Hola</p>'),
          equals('Hola'),
        );
      });

      test('elimina etiquetas de tabla', () {
        expect(
          stripHtml('<table><tr><td>Importe</td><td>\$1,500.00</td></tr></table>'),
          equals('Importe \$1,500.00'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Etiquetas de bloque con separadores
    // -------------------------------------------------------------------------
    group('etiquetas de bloque', () {
      test('br se convierte en espacio', () {
        expect(stripHtml('Línea 1<br>Línea 2'), equals('Línea 1 Línea 2'));
      });

      test('br con barra se convierte en espacio', () {
        expect(stripHtml('A<br/>B'), equals('A B'));
      });

      test('etiqueta p agrega separación', () {
        expect(stripHtml('<p>Párrafo 1</p><p>Párrafo 2</p>'), equals('Párrafo 1 Párrafo 2'));
      });

      test('li agrega bullet', () {
        expect(
          stripHtml('<ul><li>Item 1</li><li>Item 2</li></ul>'),
          contains('•'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Entidades nombradas — español
    // -------------------------------------------------------------------------
    group('entidades nombradas en español', () {
      test('decodifica &iacute; → í', () {
        expect(stripHtml('Fecha l&iacute;mite'), equals('Fecha límite'));
      });

      test('decodifica &aacute; → á', () {
        expect(stripHtml('Estado de cuenta vencido&aacute;'), equals('Estado de cuenta vencidoá'));
      });

      test('decodifica &eacute; → é', () {
        expect(stripHtml('m&eacute;s'), equals('més'));
      });

      test('decodifica &oacute; → ó', () {
        expect(stripHtml('c&oacute;digo'), equals('código'));
      });

      test('decodifica &uacute; → ú', () {
        expect(stripHtml('&uacute;ltimo'), equals('último'));
      });

      test('decodifica &ntilde; → ñ', () {
        expect(stripHtml('pa&ntilde;al'), equals('pañal'));
      });

      test('decodifica &Ntilde; → Ñ', () {
        expect(stripHtml('&Ntilde;oño'), equals('Ñoño'));
      });

      test('decodifica &iexcl; → ¡', () {
        expect(stripHtml('&iexcl;Hola!'), equals('¡Hola!'));
      });

      test('decodifica &iquest; → ¿', () {
        expect(stripHtml('&iquest;Cómo estás?'), equals('¿Cómo estás?'));
      });
    });

    // -------------------------------------------------------------------------
    // Entidades nombradas — comunes
    // -------------------------------------------------------------------------
    group('entidades nombradas comunes', () {
      test('decodifica &amp; → &', () {
        expect(stripHtml('A &amp; B'), equals('A & B'));
      });

      test('decodifica &lt; → <', () {
        expect(stripHtml('&lt;tag&gt;'), equals('<tag>'));
      });

      test('decodifica &gt; → >', () {
        expect(stripHtml('A &gt; B'), equals('A > B'));
      });

      test('decodifica &quot; → "', () {
        expect(stripHtml('Di &quot;hola&quot;'), equals('Di "hola"'));
      });

      test('decodifica &nbsp; → espacio', () {
        expect(stripHtml('A&nbsp;B').trim(), equals('A B'));
      });

      test('decodifica &middot; → ·', () {
        expect(stripHtml('Texto&middot;más texto'), equals('Texto·más texto'));
      });

      test('decodifica &euro; → €', () {
        expect(stripHtml('100&euro;'), equals('100€'));
      });
    });

    // -------------------------------------------------------------------------
    // Entidades numéricas
    // -------------------------------------------------------------------------
    group('entidades numéricas', () {
      test('decodifica entidad decimal &#39; → apostrofe', () {
        expect(stripHtml('can&#39;t'), equals("can't"));
      });

      test('decodifica entidad decimal &#9888; → símbolo advertencia', () {
        // ⚠ es U+26A0 = decimal 9888
        expect(stripHtml('&#9888; Vencido'), equals('⚠ Vencido'));
      });

      test('decodifica entidad hexadecimal &#x27; → apostrofe', () {
        expect(stripHtml('can&#x27;t'), equals("can't"));
      });

      test('decodifica entidad hexadecimal &#x26A0; → símbolo advertencia', () {
        expect(stripHtml('&#x26A0; Alerta'), equals('⚠ Alerta'));
      });
    });

    // -------------------------------------------------------------------------
    // Caso real — plantilla push_vencido del backend
    // -------------------------------------------------------------------------
    group('caso real — plantilla backend', () {
      test('convierte HTML de notificación de estado de cuenta a texto plano', () {
        const html = '<h3 style="margin:0 0 4px;color:#c0392b;">&#9888; Tu pago '
            'Abril 2026 ha vencido</h3>'
            '<p style="margin:0 0 12px;">Fecha l&iacute;mite: '
            '<b>15 de abril de 2026</b></p>'
            '<p>Alumno<br><b>Juan Garc&iacute;a</b></p>';

        final resultado = stripHtml(html);

        expect(resultado, contains('⚠'));
        expect(resultado, contains('Tu pago Abril 2026 ha vencido'));
        expect(resultado, contains('Fecha límite:'));
        expect(resultado, contains('15 de abril de 2026'));
        expect(resultado, contains('Juan García'));
        expect(resultado, isNot(contains('<')));
        expect(resultado, isNot(contains('&iacute;')));
      });

      test('no deja etiquetas residuales en texto plano', () {
        const html = '<div><table><tr><td>Total</td>'
            '<td>\$1,500.00</td></tr></table></div>';
        final resultado = stripHtml(html);
        expect(resultado, isNot(matches(RegExp(r'<[^>]+>'))));
        expect(resultado, contains('Total'));
        expect(resultado, contains('\$1,500.00'));
      });
    });

    // -------------------------------------------------------------------------
    // Normalización de espacios
    // -------------------------------------------------------------------------
    group('normalización de espacios', () {
      test('comprime múltiples espacios en uno', () {
        expect(stripHtml('A   B    C'), equals('A B C'));
      });

      test('hace trim del resultado', () {
        expect(stripHtml('  texto  '), equals('texto'));
      });

      test('múltiples etiquetas seguidas no generan dobles espacios visibles', () {
        final resultado = stripHtml('<b>A</b><b>B</b>');
        expect(resultado, equals('AB'));
      });
    });
  });
}
