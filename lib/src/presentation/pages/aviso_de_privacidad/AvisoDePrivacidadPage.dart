import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/constants/app_urls.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Página que muestra el Aviso de Privacidad embebido en un WebView.
///
/// - AppBar con botón de regreso (automático) y botón Actualizar (reload).
/// - Indicador de carga mientras el HTML se descarga.
/// - Widget de error con opción de reintentar si falla la carga.
/// - Compatible con tema claro y oscuro, Android e iOS.
class AvisoDePrivacidadPage extends StatefulWidget {
  const AvisoDePrivacidadPage({super.key});

  @override
  State<AvisoDePrivacidadPage> createState() => _AvisoDePrivacidadPageState();
}

class _AvisoDePrivacidadPageState extends State<AvisoDePrivacidadPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Inicializa el [WebViewController] y carga el endpoint del Aviso de Privacidad.
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(AppUrls.avisoDePrivacidad));
  }

  /// Recarga la página desde el servidor (petición fresca).
  void _recargar() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Leading: botón de regreso generado automáticamente por Flutter
        title: const Text(AppStrings.drawerAvisoPrivacidad),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.avisoDePrivacidadActualizar,
            onPressed: _recargar,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Contenido principal: error o WebView
          if (_errorMessage != null)
            _ErrorView(onReintentar: _recargar)
          else
            WebViewWidget(controller: _controller),

          // Barra de progreso superior mientras carga
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET DE ERROR
// ============================================================================

/// Pantalla de error con mensaje y botón de reintento.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.avisoDePrivacidadErrorCarga,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.avisoDePrivacidadReintentar),
            ),
          ],
        ),
      ),
    );
  }
}
