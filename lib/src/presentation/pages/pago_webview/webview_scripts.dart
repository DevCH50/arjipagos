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

  /// Le da a la página un `viewport` móvil, **solo si no trae uno propio**.
  ///
  /// Sin `viewport`, el WKWebView de iOS pinta la página a ~980 px de ancho y
  /// la encoge para que quepa: la letra salía diminuta en el 3D Secure de
  /// OpenPay aunque [estilosResponsivos] la pusiera a 20 px. Si la página ya
  /// declara el suyo —la del banco, por ejemplo— se respeta y no se toca.
  ///
  /// Solo se inyecta en OpenPay; ver `PeticionWebView.ajustaViewport`.
  static const String viewportMovil = '''
    (function() {
      try {
        if (document.querySelector('meta[name="viewport"]')) return;
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1';
        document.head.appendChild(meta);
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

  /// Quita el foco del campo en el que esté escribiendo el tutor.
  ///
  /// Al cerrar OpenPay con la ✕ mientras teclea la tarjeta, la capa de
  /// «Confirmando tu pago…» tapa el WebView pero el campo sigue con el foco
  /// debajo, y el teclado se quedaba abierto encima de la capa y del diálogo.
  static const String soltarFoco = '''
    (function() {
      try {
        if (document.activeElement) { document.activeElement.blur(); }
      } catch (e) {}
    })();
  ''';
}
