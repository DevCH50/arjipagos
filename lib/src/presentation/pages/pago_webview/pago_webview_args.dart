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

  const PagoWebViewArgs({
    required this.url,
    required this.params,
    required this.token,
    required this.emisorFiscalId,
  });
}
