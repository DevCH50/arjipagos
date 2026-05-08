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
      initialChildSize: 0.75,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(colorScheme),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(context).padding.bottom),
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
                  _procesarHtml(notificacion.mensaje, isDark, colorScheme),
                  textStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
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

  /// Adapta colores hardcodeados del HTML para legibilidad en ambos temas.
  ///
  /// En dark mode: sustituye solo colores oscuros (max componente RGB < 180),
  /// conservando colores brillantes como rojo o naranja que ya son visibles
  /// sobre fondo oscuro. También normaliza fondos claros y atributos legacy.
  String _procesarHtml(String html, bool isDark, ColorScheme colorScheme) {
    int ch(double v) => (v * 255.0).round().clamp(0, 255);
    String toHex(Color c) =>
        '#${ch(c.r).toRadixString(16).padLeft(2, '0')}${ch(c.g).toRadixString(16).padLeft(2, '0')}${ch(c.b).toRadixString(16).padLeft(2, '0')}';
    final fg = toHex(colorScheme.onSurface);

    if (!isDark) {
      return html.replaceAll(
        RegExp(r'(?<![a-zA-Z-])color:\s*(?:white|#fff\b|#ffffff\b)', caseSensitive: false),
        'color: $fg',
      );
    }

    // Colores con al menos un canal >= 180 son visibles en fondo oscuro → no tocar
    bool brillante(int r, int g, int b) => r > 179 || g > 179 || b > 179;
    // Nombres CSS cuyo brillo es suficiente en dark mode
    const conservar = {'red', 'crimson', 'orangered', 'orange', 'yellow', 'gold', 'lime', 'cyan', 'aqua', 'magenta', 'fuchsia', 'hotpink', 'pink', 'coral', 'salmon', 'tomato', 'deeppink'};

    final bg = toHex(colorScheme.surfaceContainerLow);

    // Atributo HTML legacy color="..." → siempre reemplazar
    String s = html.replaceAll(RegExp(r'(?<![a-zA-Z-])color="[^"]*"', caseSensitive: false), 'color="$fg"');

    // CSS hex: solo reemplaza si el color es oscuro
    s = s.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z-])color:\s*#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b', caseSensitive: false),
      (m) {
        final h = m.group(1)!;
        final x = h.length == 3;
        final r = int.parse(x ? '${h[0]}${h[0]}' : h.substring(0, 2), radix: 16);
        final g = int.parse(x ? '${h[1]}${h[1]}' : h.substring(2, 4), radix: 16);
        final b = int.parse(x ? '${h[2]}${h[2]}' : h.substring(4, 6), radix: 16);
        return brillante(r, g, b) ? m.group(0)! : 'color: $fg';
      },
    );

    // CSS rgb(): solo reemplaza si el color es oscuro
    s = s.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z-])color:\s*rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)', caseSensitive: false),
      (m) => brillante(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!))
          ? m.group(0)!
          : 'color: $fg',
    );

    // CSS named color: conserva los brillantes conocidos, reemplaza el resto
    s = s.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z-])color:\s*([a-zA-Z][a-zA-Z0-9]*)', caseSensitive: false),
      (m) => conservar.contains(m.group(1)!.toLowerCase()) ? m.group(0)! : 'color: $fg',
    );

    return s
        .replaceAll(RegExp(r'background-color:\s*#[0-9a-fA-F]{3,8}', caseSensitive: false), 'background-color: $bg')
        .replaceAll(RegExp(r'background-color:\s*rgb\([^)]*\)', caseSensitive: false), 'background-color: $bg')
        .replaceAll(RegExp(r'background-color:\s*[a-zA-Z][a-zA-Z0-9]*', caseSensitive: false), 'background-color: $bg')
        .replaceAll(RegExp(r'\bbackground:\s*#[0-9a-fA-F]{3,8}', caseSensitive: false), 'background: $bg')
        .replaceAll(RegExp(r'\bbackground:\s*rgb\([^)]*\)', caseSensitive: false), 'background: $bg')
        .replaceAll(RegExp(r'\bbackground:\s*[a-zA-Z][a-zA-Z0-9]*(?!\s*\()', caseSensitive: false), 'background: $bg')
        .replaceAll(RegExp(r'\bbgcolor="[^"]*"', caseSensitive: false), 'bgcolor="$bg"');
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
