import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';

import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/peticion_webview.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/webview_scripts.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/widgets.dart';
import 'package:flutter/material.dart';
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
  PagoWebViewArgs? _currentArgs;

  /// Emisor fiscal que se está cobrando, tomado de los argumentos de la ruta.
  ///
  /// Si faltara —no debería—, se asume el predeterminado antes que dejar el
  /// pago sin nadie a quien avisar del resultado.
  int get _emisorFiscalId =>
      _currentArgs?.emisorFiscalId ?? kEmisorFiscalPredeterminado;

  /// Carrito del emisor que se está cobrando.
  ///
  /// Va por el registro y no por `context.read`: hay un carrito por emisor y
  /// esta pantalla tiene que avisar exactamente al suyo.
  CarritoBloc get _carritoDelEmisor =>
      locator<CarritoBlocPorEmisor>().de(_emisorFiscalId);

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
      _carritoDelEmisor.add(const CarritoPagoExitosoEvent());
      // Suma el pago a la cuenta de la política de reseñas antes de mostrar el
      // diálogo, para que al cerrarlo el contador ya esté al día.
      locator<ResenaUseCases>().registrarPagoExitoso.run();
      _mostrarDialogoExito();
    } else {
      _carritoDelEmisor.add(CarritoPagoFallidoEvent(result.message));
      _mostrarDialogoError(result.message);
    }
  }

  void _mostrarDialogoExito() {
    PagoDialogs.mostrarExito(
      context: context,
      onAceptar: () {
        // Solo se recarga la lista del emisor cobrado. El otro no se entera:
        // su selección y su carrito quedan intactos.
        locator<EdoCtaListBlocPorEmisor>()
            .de(_emisorFiscalId)
            .add(const EdoCtaListRefreshEvent());
        // Y se vuelve a SU pantalla, no a la del otro emisor.
        final String ruta = ConfiguracionAdquira.para(_emisorFiscalId).ruta;
        Navigator.of(context).popUntil((route) => route.settings.name == ruta);
        _invitarACalificar();
      },
    );
  }

  /// Invita a calificar la app, si la política lo permite.
  ///
  /// Va después del `popUntil` y en un post-frame a propósito: la hoja de
  /// reseña la pinta el sistema encima de lo que haya, y debe salir sobre el
  /// estado de cuenta ya restaurado, no sobre el WebView que se está cerrando.
  ///
  /// No se espera el resultado ni se avisa de nada: el caso de uso decide si
  /// toca, y ni Apple ni Google informan de si la hoja llegó a mostrarse.
  void _invitarACalificar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator<ResenaUseCases>().solicitarResena.run();
    });
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
        _carritoDelEmisor.add(const CarritoCancelarPagoEvent());
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
