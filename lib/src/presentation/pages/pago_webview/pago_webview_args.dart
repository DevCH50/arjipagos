/// Argumentos para la página de pago WebView.
class PagoWebViewArgs {
  final String url;
  final Map<String, String> params;
  final String token;

  const PagoWebViewArgs({
    required this.url,
    required this.params,
    required this.token,
  });
}
