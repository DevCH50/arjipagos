import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:markdown/markdown.dart' as md;

/// Convierte el cuerpo de un banner a HTML para pintarlo con `HtmlWidget`.
///
/// La app ya renderiza HTML en Notificaciones con
/// `flutter_widget_from_html_core`; pasar el Markdown por aquí deja **un solo
/// renderizador** para los dos formatos, con la misma tipografía y el mismo
/// comportamiento en tema claro y oscuro. Si mañana el backend manda
/// `cuerpo_formato: "html"`, entra directo sin tocar nada.
String contenidoAHtml(String cuerpo, BannerFormato formato) {
  if (cuerpo.isEmpty) {
    return '';
  }

  switch (formato) {
    case BannerFormato.html:
      return cuerpo;

    case BannerFormato.texto:
      // Sin formato: se escapa para que un `<` del texto no se interprete como
      // etiqueta, y los saltos de línea se respetan.
      return _escaparHtml(cuerpo).replaceAll('\n', '<br>');

    case BannerFormato.markdown:
      // El backend manda saltos `\r\n`; el parser de Markdown espera `\n` y con
      // `\r` de sobra deja de reconocer listas y encabezados.
      final normalizado = cuerpo.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      return md.markdownToHtml(
        normalizado,
        extensionSet: md.ExtensionSet.gitHubWeb,
      );
  }
}

/// Escapa los caracteres que el renderizador interpretaría como HTML.
String _escaparHtml(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
