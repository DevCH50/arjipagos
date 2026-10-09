import 'dart:convert';
import 'dart:typed_data';

import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';

/// Cómo hay que abrir la pasarela en el WebView.
///
/// Existe como objeto aparte —y no como cuatro líneas dentro de la pantalla—
/// porque aquí se decide **qué se le manda a un tercero**, y eso se tiene que
/// poder probar sin montar un `WebViewController`, que en un test unitario no
/// existe.
///
/// La regla, en una frase: **si hay parámetros es Adquira y va por POST; si no
/// los hay es OpenPay y va por GET, a pelo.**
class PeticionWebView {
  /// `true` si hay que enviar un formulario (Adquira). `false` si basta con
  /// abrir la URL (OpenPay).
  final bool esPost;

  /// Cabeceras de la petición. **Vacías en el GET, y es lo importante.**
  final Map<String, String> headers;

  /// Cuerpo del formulario, ya codificado. `null` cuando no hay POST.
  final Uint8List? body;

  /// `true` si, al cargar cada página, hay que asegurarle un `viewport` móvil.
  ///
  /// **Solo OpenPay.** El simulador de 3D Secure —y en producción, la página
  /// del banco del tutor— puede no declarar `viewport`. Android lo pinta igual
  /// al ancho del teléfono, pero el WKWebView de iOS lo pinta a ~980 px y lo
  /// encoge para que quepa, con la letra incluida: en el iPhone salía
  /// diminuta. Adquira se queda como estaba, probado y sin tocar.
  final bool ajustaViewport;

  const PeticionWebView({
    required this.esPost,
    required this.headers,
    required this.body,
    required this.ajustaViewport,
  });

  /// Decide cómo abrir la pasarela a partir de los argumentos de la ruta.
  ///
  /// **Con parámetros → POST con formulario.** Es Adquira: la URL del comercio
  /// es fija y todo el pago (importe, referencia, `idexpress`…) viaja en el
  /// cuerpo. Se manda además el `Authorization` de ArjiPagos, porque tanto el
  /// destino como el retorno son sitios nuestros.
  ///
  /// **Sin parámetros → GET a secas.** Es OpenPay: la URL que dio el backend ya
  /// lleva dentro el identificador del cobro, así que no hay nada que enviar.
  ///
  /// 🔴 **En el GET no va ninguna cabecera, y menos el `Bearer`.** Esa URL es de
  /// un dominio de OpenPay, y mandarle el token de la sesión sería entregarle a
  /// un tercero la credencial del tutor: con ella se puede leer su estado de
  /// cuenta y sus facturas. El token sigue existiendo en [PagoWebViewArgs]
  /// porque el retorno del pago —que sí es nuestro— llega por redirección, y
  /// ahí no hace falta.
  factory PeticionWebView.desde(PagoWebViewArgs args) {
    if (args.params.isEmpty) {
      return const PeticionWebView(
        esPost: false,
        headers: <String, String>{},
        body: null,
        ajustaViewport: true,
      );
    }

    final String formulario = args.params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return PeticionWebView(
      esPost: true,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${args.token}',
      },
      body: Uint8List.fromList(utf8.encode(formulario)),
      ajustaViewport: false,
    );
  }
}
