import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// Bottom sheet que muestra el detalle completo de una notificación.
///
/// Al abrirse, marca automáticamente la notificación como leída enviando
/// [MarcarLeidaEvent] al [NotificacionBloc]. Renderiza el contenido HTML
/// usando el paquete `flutter_widget_from_html_core`.
///
/// Uso recomendado mediante [showModalBottomSheet] con `isScrollControlled: true`.
class NotificacionDetalleWidget extends StatefulWidget {
  /// La notificación cuyo detalle se muestra.
  final Notificacion notificacion;

  const NotificacionDetalleWidget({
    super.key,
    required this.notificacion,
  });

  @override
  State<NotificacionDetalleWidget> createState() =>
      _NotificacionDetalleWidgetState();
}

class _NotificacionDetalleWidgetState
    extends State<NotificacionDetalleWidget> {
  @override
  void initState() {
    super.initState();
    // Marcar la notificación como leída al abrir el detalle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.notificacion.isRead) {
        context.read<NotificacionBloc>().add(
              MarcarLeidaEvent(id: widget.notificacion.id),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return _DetalleContenido(
          notificacion: widget.notificacion,
          scrollController: scrollController,
        );
      },
    );
  }
}

/// Contenido interno del bottom sheet de detalle.
///
/// Separado en widget propio para mantener cada archivo bajo 200 líneas
/// y respetar el límite de anidación de 3 niveles.
class _DetalleContenido extends StatelessWidget {
  final Notificacion notificacion;
  final ScrollController scrollController;

  const _DetalleContenido({
    required this.notificacion,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(colorScheme),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Text(
                  notificacion.titulo,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatearFecha(notificacion.fecha),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                HtmlWidget(
                  notificacion.mensaje,
                  textStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  // En modo oscuro, los colores CSS hardcodeados del HTML
                  // (ej: azul oscuro para nombre del alumno) son invisibles.
                  // Sobreescribimos cualquier color inline para que use el color del tema.
                  customStylesBuilder: (element) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    if (isDark &&
                        (element.attributes['style']?.contains('color') ??
                            false)) {
                      final c = colorScheme.onSurface;
                      int ch(double v) =>
                          (v * 255.0).round().clamp(0, 255);
                      final hex =
                          '#${ch(c.r).toRadixString(16).padLeft(2, '0')}${ch(c.g).toRadixString(16).padLeft(2, '0')}${ch(c.b).toRadixString(16).padLeft(2, '0')}';
                      return {'color': hex};
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el indicador de arrastre (handle) del bottom sheet.
  Widget _buildHandle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// Formatea la fecha de la notificación en formato legible completo.
  ///
  /// Ejemplo: "08 de abril 2026, 14:30"
  String _formatearFecha(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');
    return '$dia de $mes $anio, $hora:$minutos';
  }
}
