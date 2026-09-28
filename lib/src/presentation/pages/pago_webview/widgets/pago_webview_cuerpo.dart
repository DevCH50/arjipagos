import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/pago_error_widget.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/pago_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cuerpo de la pantalla de pago: el WebView de la pasarela y lo que se le
/// pone encima según el estado.
///
/// No guarda estado: todo lo decide `PagoWebViewPage`, que es quien habla con
/// la pasarela. Las capas van de abajo arriba:
///
/// 1. El WebView, o el error de carga si la página no se pudo abrir.
/// 2. El indicador de carga mientras la pasarela navega.
/// 3. Una capa opaca cuando ya llegó la respuesta del retorno.
///
/// La capa 3 existe porque el retorno responde `{success, message}` sin
/// ningún estilo, y detrás del diálogo de resultado el padre leía ese JSON en
/// crudo. Usa el fondo del tema para quedar bien en claro y en oscuro.
class PagoWebViewCuerpo extends StatelessWidget {
  const PagoWebViewCuerpo({
    super.key,
    required this.controller,
    required this.errorMessage,
    required this.cargando,
    required this.respuestaRecibida,
    required this.onReintentar,
  });

  final WebViewController controller;

  /// Error al cargar la pasarela; `null` si no lo hay.
  final String? errorMessage;

  final bool cargando;

  /// Si ya se detectó la respuesta del retorno y hay que tapar el WebView.
  final bool respuestaRecibida;

  /// Vuelve a abrir la pasarela desde el estado de error.
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge (Android 15+): el WebView de la pasarela de pago no
    // conoce los insets del sistema. Reservamos el alto de la barra de
    // navegacion inferior para que el boton de pagar del HTML nunca quede
    // tapado por ella. El AppBar ya cubre el inset superior.
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          if (errorMessage != null)
            PagoErrorWidget(message: errorMessage!, onRetry: onReintentar)
          else
            WebViewWidget(controller: controller),
          if (cargando) const PagoLoadingWidget(),
          if (respuestaRecibida)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
        ],
      ),
    );
  }
}
