import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';

import 'package:arjipagos/src/data/dataSource/remote/services/OpenpayService.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/aviso_cierre_cobro.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/desenlace_pago.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/peticion_webview.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/webview_scripts.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Re-exportar PagoWebViewArgs para mantener compatibilidad
export 'pago_webview_args.dart';

/// Página con WebView para procesar el pago en la pasarela del emisor.
///
/// Sirve a las dos: **Adquira** (emisor 1, "Pagos Pendientes") y **OpenPay**
/// (emisor 2, "Otros pagos"). La diferencia está solo en cómo se abre la URL
/// —ver [_PagoWebViewPageState._cargarPagina]—, porque las dos terminan
/// aterrizando en un retorno de nuestro backend que responde
/// `{success, message}`, que es justo lo que busca
/// `WebViewScripts.detectarRespuestaJson`. De ahí para abajo —el canal, los
/// diálogos, vaciar el carrito y recargar el estado de cuenta— todo es común.
///
/// **OpenPay no vuelve solo a la app.** Si el tutor cierra sin pulsar su botón
/// «Finalizar», el retorno no llega nunca; por eso, al cerrar un cobro de
/// OpenPay, se pregunta al backend en qué quedó. Ver [_PagoWebViewPageState._confirmarSalir].
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

  /// Si ya se detectó la respuesta `{success, message}` del retorno.
  ///
  /// Mientras sea `true`, una capa opaca tapa el WebView: el retorno es JSON
  /// sin estilo, y sin esa capa el padre lo leía en crudo detrás del diálogo.
  bool _respuestaRecibida = false;

  /// Si se está preguntando al backend en qué quedó el cobro de OpenPay.
  bool _verificando = false;
  PagoWebViewArgs? _currentArgs;

  /// Si cada página cargada necesita un `viewport` móvil (solo OpenPay).
  /// Lo decide [PeticionWebView.ajustaViewport] al abrir la pasarela.
  bool _ajustaViewport = false;

  /// Qué pasa al terminar el pago, para el emisor que se está cobrando.
  ///
  /// Si faltara el emisor en los argumentos —no debería—, se asume el
  /// predeterminado antes que dejar el pago sin nadie a quien avisar.
  DesenlacePago get _desenlace => DesenlacePago(
    _currentArgs?.emisorFiscalId ?? kEmisorFiscalPredeterminado,
  );

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
        if (_ajustaViewport) {
          _controller.runJavaScript(WebViewScripts.viewportMovil);
        }
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
      _cargarPagina(args);
    } else if (args is String) {
      _controller.loadRequest(Uri.parse(args));
    }
  }

  /// Abre la pasarela del emisor que se está cobrando.
  ///
  /// El **qué** —GET o POST, con qué cabeceras y con qué cuerpo— lo decide
  /// [PeticionWebView.desde], que está fuera para poder probarlo; aquí solo
  /// queda el **cómo** se le pide al controlador.
  void _cargarPagina(PagoWebViewArgs args) {
    final Uri url = Uri.parse(args.url);
    final peticion = PeticionWebView.desde(args);
    _ajustaViewport = peticion.ajustaViewport;

    if (!peticion.esPost) {
      _controller.loadRequest(url);
      return;
    }

    _controller.loadRequest(
      url,
      method: LoadRequestMethod.post,
      headers: peticion.headers,
      body: peticion.body,
    );
  }

  void _recargarWebView() {
    if (_currentArgs != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _pagoProcessed = false;
        _respuestaRecibida = false;
      });
      _cargarPagina(_currentArgs!);
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
    setState(() => _respuestaRecibida = true);
    if (result.success) {
      _desenlace.exito(context);
    } else if (result.referenciaYaCobrada) {
      // Adquira dice que esa referencia ya se usó: lo más probable es que se
      // cobrara antes. Sin «Reintentar» y con el carrito vacío.
      _desenlace.avisoDeCierre(context, AvisoCierreCobro.referenciaYaCobrada);
    } else if (_currentArgs?.verificaAlCerrar ?? false) {
      // En OpenPay un retorno fallido no se cree sin más: puede ser «pagaste
      // pero no identificamos los cargos», donde el dinero sí salió. Manda el
      // estado del cobro, igual que al cerrar con la ✕.
      _verificarCobro();
    } else {
      _desenlace.fallo(context, result.message, onReintentar: _recargarWebView);
    }
  }

  /// Cerrar con la ✕ o con el botón atrás.
  ///
  /// En un cobro de OpenPay sin retorno **no se pregunta** «¿cancelar el
  /// pago?»: el tutor puede estar en el comprobante de un pago ya hecho, y esa
  /// pregunta lo asustaría. Se consulta en qué quedó y se le dice. En Adquira,
  /// o si ya se procesó el retorno, se cierra como siempre.
  void _confirmarSalir() {
    if (_verificando) {
      return;
    }
    if (!_pagoProcessed && (_currentArgs?.verificaAlCerrar ?? false)) {
      _verificarCobro();
      return;
    }
    _desenlace.confirmarCancelar(context);
  }

  /// Pregunta al backend en qué quedó el cobro y enseña el diálogo que toca.
  ///
  /// La tabla de estados está en [AvisoCierreCobro]; `pagado` usa el diálogo
  /// de éxito de siempre.
  Future<void> _verificarCobro() async {
    // Sin esto el teclado del campo de la tarjeta se queda abierto encima.
    _controller.runJavaScript(WebViewScripts.soltarFoco);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    setState(() => _verificando = true);
    _pagoProcessed = true;

    final resultado = await locator<OpenpayService>().verificarCobro(
      _currentArgs!.orderId!,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _verificando = false;
      _respuestaRecibida = true;
    });

    final AvisoCierreCobro? aviso = AvisoCierreCobro.para(resultado);
    if (aviso == null) {
      _desenlace.exito(context);
    } else {
      _desenlace.avisoDeCierre(context, aviso);
    }
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
          title: const Text(AppStrings.pagoWebViewTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalir,
          ),
        ),
        body: PagoWebViewCuerpo(
          controller: _controller,
          errorMessage: _errorMessage,
          cargando: _isLoading,
          respuestaRecibida: _respuestaRecibida,
          verificando: _verificando,
          onReintentar: () {
            if (_currentArgs != null) {
              _cargarPagina(_currentArgs!);
            }
          },
        ),
      ),
    );
  }
}
