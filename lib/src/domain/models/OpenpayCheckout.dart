/// Cobro recién creado en OpenPay, visto desde la app.
///
/// Es lo que devuelve `POST /api/v1/openpay/crear-cargo`: el backend ya habló
/// con OpenPay y lo único que la app necesita de vuelta es **a dónde mandar al
/// tutor**. Ni el objeto de la transacción, ni el estado, ni la tarjeta: nada
/// de eso existe todavía cuando se crea el cobro, porque el tutor aún no ha
/// tecleado nada.
///
/// El resultado del pago no llega por aquí: llega al aterrizar el WebView en el
/// `redirect_url` que el backend le dio a OpenPay, que responde
/// `{success, message}` igual que el retorno de Adquira.
library;

/// URL del formulario de OpenPay y los datos con los que se creó el cobro.
class OpenpayCheckout {
  /// URL del formulario alojado de OpenPay. **Es lo único imprescindible.**
  ///
  /// Se abre con un GET en el WebView. No lleva token de ArjiPagos: es un
  /// dominio de OpenPay y mandarle la cabecera `Authorization` de la app sería
  /// filtrar la sesión del tutor a un tercero.
  final String url;

  /// Identificador del cobro para OpenPay.
  ///
  /// El backend lo forma como `referencia + "-N" + marca de tiempo`. El sufijo
  /// no es adorno: OpenPay exige que `order_id` sea único entre **todas** las
  /// transacciones del comercio, así que sin él un segundo intento sobre los
  /// mismos cargos —después de una tarjeta rechazada, por ejemplo— sería
  /// rechazado por duplicado. Se guarda solo para poder rastrear el cobro en
  /// el panel de OpenPay si algo se pierde.
  final String orderId;

  /// Importe que se va a cobrar, **calculado por el servidor**.
  ///
  /// Se usa para dejarlo en el log y poder contrastarlo con el total que el
  /// usuario tenía en pantalla. Si no coinciden, lo que vale es éste.
  final double importe;

  const OpenpayCheckout({
    required this.url,
    required this.orderId,
    required this.importe,
  });

  /// Construye el cobro desde la respuesta del backend.
  ///
  /// Es tolerante con los tipos a propósito: `importe` puede llegar como
  /// número o como texto según cómo serialice PHP el decimal, y `order_id`
  /// puede faltar sin que eso impida pagar. Lo único que no se perdona es que
  /// falte la URL, y de eso se encarga quien llama comprobando [urlValida].
  factory OpenpayCheckout.fromJson(Map<String, dynamic> json) {
    return OpenpayCheckout(
      url: (json['url'] ?? '').toString().trim(),
      orderId: (json['order_id'] ?? '').toString(),
      importe: _aDouble(json['importe']),
    );
  }

  /// `true` si la URL sirve para abrir el formulario.
  ///
  /// Se exige `https` además de que no esté vacía: una URL de pago por `http`
  /// viajaría en claro, y en iOS la bloquearía ATS dejando la pantalla en
  /// blanco sin explicación.
  bool get urlValida =>
      url.isNotEmpty && Uri.tryParse(url)?.scheme == 'https';

  static double _aDouble(Object? valor) {
    if (valor is num) {
      return valor.toDouble();
    }
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
