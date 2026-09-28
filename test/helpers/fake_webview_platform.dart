/// WebView falso para montar en test las pantallas que llevan uno.
///
/// El WebView de verdad es una vista nativa (WKWebView en iOS, el de Chromium
/// en Android) que no existe en `flutter test`. Este doble acepta todo lo que
/// `PagoWebViewPage` le pide al controlador y no hace nada, salvo dos cosas
/// que los tests necesitan ver:
///
/// - [FakeWebViewPlatform.scripts]: qué JavaScript se le pidió a la página.
/// - [FakeWebViewPlatform.enviarPorCanal]: simula que la página mandó un
///   mensaje por un canal de JavaScript —el retorno `{success, message}` llega
///   así por `PagoResultado`—.
///
/// Uso: `WebViewPlatform.instance = FakeWebViewPlatform();` en `setUp`.
library;

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class FakeWebViewPlatform extends WebViewPlatform {
  /// JavaScript que se le pidió ejecutar a la página, en orden.
  final List<String> scripts = [];

  final Map<String, JavaScriptChannelParams> _canales = {};

  /// Entrega [mensaje] al canal [canal] como si lo mandara la página.
  void enviarPorCanal(String canal, String mensaje) {
    _canales[canal]!.onMessageReceived(JavaScriptMessage(message: mensaje));
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakeWidget(params);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _FakeController(params, this);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _FakeNavigationDelegate(params);
}

/// Ocupa todo su espacio, como el WebView de verdad.
class _FakeWidget extends PlatformWebViewWidget {
  _FakeWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params, this._plataforma) : super.implementation();

  final FakeWebViewPlatform _plataforma;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    _plataforma._canales[params.name] = params;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> clearLocalStorage() async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {
    _plataforma.scripts.add(javaScript);
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(void Function(String url) onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(
    void Function(String url) onPageFinished,
  ) async {}

  @override
  Future<void> setOnWebResourceError(
    void Function(WebResourceError error) onWebResourceError,
  ) async {}

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}
}
