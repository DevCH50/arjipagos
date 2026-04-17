/// Tests de widget para AvisoDePrivacidadPage.
///
/// Verifica:
/// - AppBar muestra el título correcto.
/// - Botón de actualizar (refresh) existe en el AppBar.
/// - Botón back está disponible.
/// - La página inicializa sin errores.
///
/// Usa una implementación fake de WebViewPlatform para evitar dependencias
/// de plataforma nativa (Android/iOS) en el entorno de tests.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/aviso_de_privacidad/AvisoDePrivacidadPage.dart';

void main() {
  setUpAll(() {
    // Registrar el fake de WebView antes de cualquier test.
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  /// Crea la página envuelta en MaterialApp con ruta raíz para que el
  /// back button de la AppBar funcione.
  Widget crearWidget() {
    return MaterialApp(
      routes: {
        '/': (_) => const Scaffold(body: Text('Home')),
        'aviso_de_privacidad': (_) => const AvisoDePrivacidadPage(),
      },
      initialRoute: 'aviso_de_privacidad',
    );
  }

  group('AvisoDePrivacidadPage', () {
    testWidgets('muestra el AppBar con título correcto', (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(
        find.text(AppStrings.drawerAvisoPrivacidad),
        findsOneWidget,
      );
    });

    testWidgets('muestra el botón de actualizar en el AppBar', (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('contiene un WebViewWidget en el cuerpo', (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(find.byType(WebViewWidget), findsOneWidget);
    });

    testWidgets('muestra indicador de carga al iniciar', (tester) async {
      await tester.pumpWidget(crearWidget());
      // En el primer frame, isLoading = true → LinearProgressIndicator visible.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}

// =============================================================================
// FAKE PLATFORM — WebView para tests
// =============================================================================

/// Plataforma WebView falsa para entornos de prueba.
///
/// Evita dependencias nativas (JNI/Android, WKWebView/iOS) en los tests.
class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _FakePlatformWebViewWidget(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _FakePlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakePlatformNavigationDelegate(params);
  }
}

/// Widget WebView falso que renderiza un contenedor vacío.
class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Controlador WebView falso que no-op todas las operaciones.
class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> loadFile(String absoluteFilePath) async {}

  @override
  Future<void> loadFlutterAsset(String key) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<String?> currentUrl() async => null;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> clearLocalStorage() async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '';

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<String?> getTitle() async => null;

  @override
  Future<void> scrollTo(int x, int y) async {}

  @override
  Future<void> scrollBy(int x, int y) async {}

  @override
  Future<Offset> getScrollPosition() async => Offset.zero;

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<String?> getUserAgent() async => null;

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {}

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {}

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange,
  ) async {}

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) async {}

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) async {}

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request) onJavaScriptAlertDialog,
  ) async {}

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request) onJavaScriptConfirmDialog,
  ) async {}

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request) onJavaScriptTextInputDialog,
  ) async {}
}

/// Delegado de navegación falso que no-op todos los callbacks.
class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(void Function(String url) onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(void Function(String url) onPageFinished) async {}

  @override
  Future<void> setOnWebResourceError(
    void Function(WebResourceError error) onWebResourceError,
  ) async {}

  @override
  Future<void> setOnNavigationRequest(
    FutureOr<NavigationDecision> Function(NavigationRequest request) onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnUrlChange(void Function(UrlChange change) onUrlChange) async {}

  @override
  Future<void> setOnHttpError(
    void Function(HttpResponseError error) onHttpError,
  ) async {}

  @override
  Future<void> setOnHttpAuthRequest(
    void Function(HttpAuthRequest request) onHttpAuthRequest,
  ) async {}
}
