import 'package:arjipagos/src/core/utils/html_utils.dart';
import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:flutter/material.dart';

/// Widget que representa una fila individual en la lista de notificaciones.
///
/// Muestra el título, un extracto del mensaje, la fecha relativa y el estado
/// de lectura con indicadores visuales. No leídas se resaltan con fondo tenue.
class NotificacionItemWidget extends StatelessWidget {
  /// La notificación a mostrar.
  final Notificacion notificacion;

  /// Callback que se invoca al presionar el item.
  final VoidCallback onTap;

  const NotificacionItemWidget({
    super.key,
    required this.notificacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noLeida = !notificacion.isRead;

    return ListTile(
      tileColor: noLeida
          ? colorScheme.primaryContainer.withValues(alpha: 0.15)
          : null,
      leading: _buildLeading(colorScheme, noLeida),
      title: Text(
        stripHtml(notificacion.titulo),
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: noLeida ? FontWeight.bold : FontWeight.normal,
          color: colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        stripHtml(notificacion.mensaje),
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildTrailing(colorScheme, textTheme, noLeida),
      onTap: onTap,
    );
  }

  /// Construye el avatar circular con ícono de campana.
  Widget _buildLeading(ColorScheme colorScheme, bool noLeida) {
    return CircleAvatar(
      backgroundColor: noLeida
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: Icon(
        noLeida ? Icons.notifications : Icons.notifications_outlined,
        color: noLeida
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  /// Construye la columna derecha con fecha relativa y punto indicador.
  Widget _buildTrailing(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool noLeida,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _fechaRelativa(notificacion.fecha),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (noLeida) ...[
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  /// Calcula una representación relativa de la fecha respecto al momento actual.
  ///
  /// - Menos de 60 minutos: "hace X min"
  /// - Menos de 24 horas: "hace X h"
  /// - Menos de 48 horas: "ayer"
  /// - 48 horas o más: formato "dd/MM/yy"
  String _fechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 60) {
      final minutos = diferencia.inMinutes.clamp(0, 59);
      return 'hace ${minutos}min';
    } else if (diferencia.inHours < 24) {
      return 'hace ${diferencia.inHours}h';
    } else if (diferencia.inHours < 48) {
      return 'ayer';
    } else {
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = fecha.month.toString().padLeft(2, '0');
      final anio = fecha.year.toString().substring(2);
      return '$dia/$mes/$anio';
    }
  }
}
