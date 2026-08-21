import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/error_widget.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketBloc.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketEvent.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketState.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_acciones_bar.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_listo_widget.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_loading_widget.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_visor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Cuerpo de la pantalla del ticket: descarga, visor y acciones.
///
/// El PDF se muestra **dentro** de la app. Salir a otra aplicación dejó de ser
/// el camino por defecto y pasó a ser una acción que el usuario elige, así que
/// ya no hay traspaso automático al terminar la descarga.
///
/// Reutiliza [EdoCtaErrorWidget] porque su contenido ya es genérico
/// (mensaje + reintentar) y no depende del flujo de pagos pendientes.
class TicketBody extends StatefulWidget {
  const TicketBody({super.key});

  @override
  State<TicketBody> createState() => _TicketBodyState();
}

class _TicketBodyState extends State<TicketBody> {
  /// El visor no pudo pintar el PDF; se muestra el panel de respaldo.
  bool _visorFallo = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketBloc, TicketState>(
      listener: _onStateChange,
      builder: (context, state) {
        if (state.errorMessage != null && !state.tieneArchivo) {
          return EdoCtaErrorWidget(
            message: state.errorMessage!,
            onRetry: () => _reintentar(state),
          );
        }

        if (!state.tieneArchivo) {
          return const TicketLoadingWidget();
        }

        return Column(
          children: [
            Expanded(child: _documento(state)),
            TicketAccionesBar(
              onCompartir: () => _compartir(state),
              onAbrirFuera: () => _abrirFuera(state),
            ),
          ],
        );
      },
    );
  }

  /// El ticket en el visor, o el panel de respaldo si no se pudo renderizar.
  Widget _documento(TicketState state) {
    if (_visorFallo) {
      return TicketListoWidget(
        folio: state.folio,
        explicacion: AppStrings.ticketErrorVisor,
      );
    }

    return TicketVisorWidget(
      // La clave ata el visor al archivo: si un reintento cambia la ruta, el
      // estado del visor se recrea en vez de arrastrar el documento anterior.
      key: ValueKey<String>(state.rutaArchivo),
      rutaArchivo: state.rutaArchivo,
      onErrorVisor: () => setState(() => _visorFallo = true),
    );
  }

  /// Muestra el error de descarga en diálogo (nunca Toast ni SnackBar).
  void _onStateChange(BuildContext context, TicketState state) {
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      _mostrarDialogoError(context, state.errorMessage!);
    }
  }

  /// Vuelve a pedir el ticket al servidor.
  void _reintentar(TicketState state) {
    setState(() => _visorFallo = false);
    context.read<TicketBloc>().add(
          TicketDescargarEvent(url: state.url, folio: state.folio),
        );
  }

  /// Abre el PDF con el visor que el usuario elija.
  ///
  /// En Android esto es un `ACTION_VIEW`: la hoja de compartir es un
  /// `ACTION_SEND` y solo lista apps que **reciben** el archivo, así que por sí
  /// sola no garantiza que el ticket pueda verse. En iOS abre el preview
  /// nativo. Si no hay ninguna app capaz de mostrar un PDF se cae a la hoja de
  /// compartir, desde donde el usuario al menos puede guardarlo o enviarlo.
  Future<void> _abrirFuera(TicketState state) async {
    try {
      final resultado = await OpenFilex.open(
        state.rutaArchivo,
        type: 'application/pdf',
      );

      if (resultado.type == ResultType.done) {
        return;
      }

      AppLogger.warning(
        'El visor externo no abrió el ticket (${resultado.type}); '
        'se ofrece la hoja de compartir',
        tag: 'Ticket',
      );
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error abriendo el ticket fuera: $e', tag: 'Ticket');
    }

    if (!mounted) {
      return;
    }
    await _compartir(state);
  }

  /// Entrega el PDF al sistema para guardarlo o enviarlo.
  Future<void> _compartir(TicketState state) async {
    try {
      final asunto = state.folio.isEmpty
          ? AppStrings.ticketTitle
          : '${AppStrings.ticketTitle} ${state.folio}';

      // En iPad la hoja de compartir es un popover y iOS exige el rectángulo
      // desde el que sale; sin esto la app truena al abrirla.
      final caja = context.findRenderObject() as RenderBox?;
      final origen = caja == null || !caja.hasSize
          ? null
          : caja.localToGlobal(Offset.zero) & caja.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(state.rutaArchivo, mimeType: 'application/pdf')],
          subject: asunto,
          sharePositionOrigin: origen,
        ),
      );
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error(
        'No se pudo entregar el ticket al sistema: $e',
        tag: 'Ticket',
      );
      if (!mounted) {
        return;
      }
      _mostrarDialogoError(context, AppStrings.ticketErrorAbrir);
    }
  }

  /// Muestra diálogo de error (nunca Toast ni SnackBar).
  void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }
}
