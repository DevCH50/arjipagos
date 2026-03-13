/// Scripts de JavaScript para inyectar en el WebView de pagos.
class WebViewScripts {
  /// Script para mejorar la legibilidad del contenido.
  static const String estilosResponsivos = '''
    (function() {
      try {
        if (document.getElementById('arjipagos-styles')) return;
        var style = document.createElement('style');
        style.id = 'arjipagos-styles';
        style.textContent = `
          html, body { font-size: 20px !important; }
          input, select, textarea, button { font-size: 18px !important; }
        `;
        document.head.appendChild(style);
      } catch (e) {}
    })();
  ''';

  /// Script para detectar respuesta JSON del servidor.
  static const String detectarRespuestaJson = '''
    (function() {
      try {
        var bodyText = document.body.innerText || document.body.textContent;
        bodyText = bodyText.trim();
        if (!bodyText.startsWith('{') && !bodyText.startsWith('[')) {
          var preElement = document.querySelector('pre');
          if (preElement) {
            bodyText = preElement.textContent.trim();
          }
        }
        if (bodyText.startsWith('{')) {
          try {
            var json = JSON.parse(bodyText);
            if (json.hasOwnProperty('success') && json.hasOwnProperty('message')) {
              PagoResultado.postMessage(bodyText);
            }
          } catch (parseError) {}
        }
      } catch (e) {}
    })();
  ''';
}
