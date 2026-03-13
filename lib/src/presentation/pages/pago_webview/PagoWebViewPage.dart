import 'dart:convert';
import 'dart:typed_data';

import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/webview_scripts.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Re-exportar PagoWebViewArgs para mantener compatibilidad
export 'pago_webview_args.dart';

/// Página con WebView para procesar el pago en Adquira México.
class PagoWebViewPage extends StatefulWidget {
  const PagoWebViewPage({super.key});

  @override
  State<PagoWebViewPage> createState() => _PagoWebViewPageState();
}

class _PagoWebViewPageState extends State<PagoWebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;
  bool _pagoProcessed = false;
  PagoWebViewArgs? _currentArgs;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..addJavaScriptChannel(
        'PagoResultado',
        onMessageReceived: (msg) => _procesarJsonRespuesta(msg.message),
      )
      ..setNavigationDelegate(_buildNavigationDelegate())
      ..clearCache()
      ..clearLocalStorage();
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) => setState(() {
        _isLoading = true;
        _errorMessage = null;
      }),
      onPageFinished: (_) {
        setState(() => _isLoading = false);
        _controller.runJavaScript(WebViewScripts.estilosResponsivos);
        _controller.runJavaScript(WebViewScripts.detectarRespuestaJson);
      },
      onWebResourceError: (error) => setState(() {
        _isLoading = false;
        _errorMessage = error.description;
      }),
      onNavigationRequest: (_) => NavigationDecision.navigate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PagoWebViewArgs) {
      _currentArgs = args;
      _loadPostRequest(args);
    } else if (args is String) {
      _controller.loadRequest(Uri.parse(args));
    }
  }

  void _loadPostRequest(PagoWebViewArgs args) {
    final bodyString = args.params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    _controller.loadRequest(
      Uri.parse(args.url),
      method: LoadRequestMethod.post,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${args.token}',
      },
      body: Uint8List.fromList(utf8.encode(bodyString)),
    );
  }

  void _recargarWebView() {
    if (_currentArgs != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _pagoProcessed = false;
      });
      _loadPostRequest(_currentArgs!);
    }
  }

  void _procesarJsonRespuesta(String jsonString) {
    if (_pagoProcessed || !mounted) {
      return;
    }

    final result = PagoResponseHandler.procesarJson(jsonString);
    if (!result.processed) {
      return;
    }

    _pagoProcessed = true;
    if (result.success) {
      context.read<CarritoBloc>().add(const CarritoPagoExitosoEvent());
      _mostrarDialogoExito();
    } else {
      context.read<CarritoBloc>().add(CarritoPagoFallidoEvent(result.message));
      _mostrarDialogoError(result.message);
    }
  }

  void _mostrarDialogoExito() {
    PagoDialogs.mostrarExito(
      context: context,
      onAceptar: () {
        context.read<EdoCtaListBloc>().add(const EdoCtaListRefreshEvent());
        Navigator.of(context).popUntil((route) => route.settings.name == 'edo_cta');
      },
    );
  }

  void _mostrarDialogoError(String mensaje) {
    PagoDialogs.mostrarError(
      context: context,
      mensaje: mensaje,
      onVolver: () => Navigator.pop(context),
      onReintentar: _recargarWebView,
    );
  }

  void _confirmarSalir() {
    PagoDialogs.confirmarCancelar(
      context: context,
      onCancelar: () {
        context.read<CarritoBloc>().add(const CarritoCancelarPagoEvent());
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmarSalir();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Realizar Pago'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalir,
          ),
        ),
        body: Stack(
          children: [
            if (_errorMessage != null)
              PagoErrorWidget(
                message: _errorMessage!,
                onRetry: () {
                  if (_currentArgs != null) {
                    _loadPostRequest(_currentArgs!);
                  }
                },
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading) const PagoLoadingWidget(),
          ],
        ),
      ),
    );
  }
}
