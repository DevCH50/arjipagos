/// Argumentos para la página de pago WebView.
class PagoWebViewArgs {
  final String url;
  final Map<String, String> params;
  final String token;

  /// Emisor fiscal que se está cobrando.
  ///
  /// Decide a qué carrito se le avisa del resultado y a qué pantalla se vuelve
  /// al terminar. Sin él, pagar en un emisor notificaba al carrito del otro y
  /// devolvía al usuario a la pantalla equivocada.
  final int emisorFiscalId;

  /// `order_id` del cobro de OpenPay; `null` en Adquira.
  ///
  /// Con él, al cerrar el WebView sin que llegara el retorno, se pregunta al
  /// backend en qué quedó el cobro. Ver `PagoWebViewPage._confirmarSalir`.
  final String? orderId;

  const PagoWebViewArgs({
    required this.url,
    required this.params,
    required this.token,
    required this.emisorFiscalId,
    this.orderId,
  });

  /// `true` si al cerrar hay que consultar el estado del cobro.
  ///
  /// Solo en OpenPay y solo si el backend mandó el `order_id`: sin él no hay
  /// nada que consultar, y se cierra como siempre, preguntando antes.
  bool get verificaAlCerrar => orderId?.isNotEmpty ?? false;
}
