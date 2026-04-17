/// Utilidades de texto HTML para ArjiPagos.
///
/// Funciones de nivel de archivo para procesar contenido HTML recibido
/// del backend y convertirlo en texto plano legible.
library;

/// Elimina todas las etiquetas HTML de [html] y decodifica entidades comunes.
///
/// Soporta:
/// - Etiquetas de bloque (`<br>`, `<p>`, `<li>`) convertidas a espacios/bullets.
/// - Entidades numéricas decimales (`&#039;`) y hexadecimales (`&#x27;`).
/// - Entidades nombradas comunes, incluyendo vocales con tilde y caracteres españoles.
///
/// Útil para convertir el campo `message` del backend (que contiene HTML)
/// en texto plano apto para mostrar en banners de notificación o subtítulos.
///
/// Ejemplo:
/// ```dart
/// stripHtml('<h3>Tu estado de cuenta ha vencido</h3>');
/// // → 'Tu estado de cuenta ha vencido'
///
/// stripHtml('Fecha l&iacute;mite: <b>15 de abril</b>');
/// // → 'Fecha límite: 15 de abril'
/// ```
String stripHtml(String html) {
  if (html.isEmpty) {
    return html;
  }

  // 1. Reemplazar etiquetas de bloque con separadores legibles.
  String texto = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), ' • ')
      // Celdas y filas de tabla separadas por espacio.
      .replaceAll(RegExp(r'</td>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</th>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</tr>', caseSensitive: false), ' ');

  // 2. Eliminar todas las etiquetas HTML restantes.
  texto = texto.replaceAll(RegExp(r'<[^>]+>'), '');

  // 3. Decodificar entidades numéricas hexadecimales (ej: &#x27; → ').
  texto = texto.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    },
  );

  // 4. Decodificar entidades numéricas decimales (ej: &#039; → ').
  texto = texto.replaceAllMapped(
    RegExp(r'&#([0-9]+);'),
    (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    },
  );

  // 5. Decodificar entidades HTML nombradas.
  const entidades = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    // Vocales con tilde (minúsculas y mayúsculas)
    '&aacute;': 'á', '&Aacute;': 'Á',
    '&eacute;': 'é', '&Eacute;': 'É',
    '&iacute;': 'í', '&Iacute;': 'Í',
    '&oacute;': 'ó', '&Oacute;': 'Ó',
    '&uacute;': 'ú', '&Uacute;': 'Ú',
    '&uuml;': 'ü', '&Uuml;': 'Ü',
    '&ntilde;': 'ñ', '&Ntilde;': 'Ñ',
    // Puntuación especial en español
    '&iexcl;': '¡', '&iquest;': '¿',
    // Comillas tipográficas
    '&lsquo;': '\u2018', '&rsquo;': '\u2019',
    '&ldquo;': '\u201C', '&rdquo;': '\u201D',
    '&laquo;': '«', '&raquo;': '»',
    // Guiones y puntos suspensivos
    '&mdash;': '\u2014', '&ndash;': '\u2013',
    '&hellip;': '\u2026',
    // Símbolos frecuentes
    '&copy;': '©', '&reg;': '®', '&trade;': '™',
    '&euro;': '€', '&cent;': '¢', '&pound;': '£',
    '&bull;': '•', '&middot;': '·',
  };

  for (final entry in entidades.entries) {
    texto = texto.replaceAll(entry.key, entry.value);
  }

  // 6. Comprimir espacios múltiples y saltos de línea.
  return texto
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
