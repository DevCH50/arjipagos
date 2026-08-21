import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Visor del PDF del ticket **dentro** de la app.
///
/// El ticket ya no se entrega a una aplicación ajena: se pinta aquí. Eso evita
/// toda la clase de fallos que trae el traspaso a otra app —el diálogo
/// "Abrir con" se apila dentro de nuestra tarea y el regreso queda a merced de
/// cómo Android trate la tarea y la memoria del proceso—, y de paso el cliente
/// ve su comprobante sin salir de Arjipagos.
///
/// La hoja del PDF se deja en blanco a propósito, también en tema oscuro: es un
/// documento fiscal y alterarle los colores lo desfigura. Lo que sí se adapta
/// al tema es el fondo sobre el que descansa, de modo que la página se lee como
/// una hoja de papel sobre un escritorio en ambos modos.
class TicketVisorWidget extends StatefulWidget {
  /// Ruta absoluta del PDF ya descargado en la carpeta temporal.
  final String rutaArchivo;

  /// Se invoca si el PDF no se puede renderizar, para que la pantalla ofrezca
  /// las salidas de siempre (compartir o abrir con otra app).
  final VoidCallback onErrorVisor;

  const TicketVisorWidget({
    super.key,
    required this.rutaArchivo,
    required this.onErrorVisor,
  });

  @override
  State<TicketVisorWidget> createState() => _TicketVisorWidgetState();
}

class _TicketVisorWidgetState extends State<TicketVisorWidget> {
  late final PdfControllerPinch _controlador;

  /// Página visible y total de páginas del documento.
  int _pagina = 1;
  int _paginas = 0;

  @override
  void initState() {
    super.initState();
    _controlador = PdfControllerPinch(
      document: PdfDocument.openFile(widget.rutaArchivo),
    );
  }

  @override
  void didUpdateWidget(TicketVisorWidget anterior) {
    super.didUpdateWidget(anterior);
    // Un reintento reescribe el archivo: hay que recargar el documento o el
    // visor seguiría mostrando el anterior.
    if (anterior.rutaArchivo != widget.rutaArchivo) {
      _controlador.loadDocument(PdfDocument.openFile(widget.rutaArchivo));
    }
  }

  @override
  void dispose() {
    // Libera el documento nativo; sin esto el PDF se queda en memoria.
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Stack(
      children: [
        PdfViewPinch(
          controller: _controlador,
          padding: 12,
          minScale: 1,
          // 5x basta para leer un ticket; el 20x por defecto solo pixela.
          maxScale: 5,
          backgroundDecoration: BoxDecoration(
            color: colores.surfaceContainerHighest,
          ),
          onDocumentLoaded: _alCargarDocumento,
          onPageChanged: _alCambiarPagina,
          onDocumentError: _alFallarDocumento,
          builders: const PdfViewPinchBuilders<DefaultBuilderOptions>(
            options: DefaultBuilderOptions(),
            documentLoaderBuilder: _cargando,
            pageLoaderBuilder: _cargando,
          ),
        ),
        if (_paginas > 1) _IndicadorPagina(actual: _pagina, total: _paginas),
      ],
    );
  }

  /// Indicador mientras el motor nativo abre el documento o pinta una página.
  static Widget _cargando(BuildContext context) =>
      const TicketLoadingWidget(mensaje: AppStrings.ticketPreparando);

  void _alCargarDocumento(PdfDocument documento) {
    setState(() => _paginas = documento.pagesCount);
  }

  void _alCambiarPagina(int pagina) {
    setState(() => _pagina = pagina);
  }

  /// El PDF no se pudo renderizar: se avisa a la pantalla para que ofrezca
  /// compartirlo o abrirlo fuera, en vez de dejar al usuario sin salida.
  void _alFallarDocumento(Object error) {
    AppLogger.error('El visor no pudo abrir el PDF: $error', tag: 'Ticket');
    // El aviso se aplaza: llega durante el build del visor y cambiar el estado
    // del padre en ese momento lanza excepción.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onErrorVisor();
      }
    });
  }
}

/// Píldora discreta con la página actual, solo si el ticket tiene varias.
class _IndicadorPagina extends StatelessWidget {
  final int actual;
  final int total;

  const _IndicadorPagina({required this.actual, required this.total});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colores.inverseSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            AppStrings.ticketPaginaDe(actual, total),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colores.onInverseSurface,
                ),
          ),
        ),
      ),
    );
  }
}
