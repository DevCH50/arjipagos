import 'package:flutter/material.dart';

/// Icono con fondo redondeado de las opciones de menú.
///
/// Es el distintivo visual de las pantallas tipo menú —Menú Principal y
/// Configuraciones—. Vive aparte para que las dos lo dibujen igual: si cambia
/// aquí, cambia en ambas.
///
/// Compatible con tema claro y oscuro: el fondo baja de opacidad en oscuro
/// para no deslumbrar.
class IconoDeMenu extends StatelessWidget {
  /// Icono a mostrar.
  final IconData icono;

  /// Si es `false`, el icono se pinta apagado (opción deshabilitada).
  final bool habilitado;

  const IconoDeMenu({super.key, required this.icono, this.habilitado = true});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.3 : 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icono,
        color: habilitado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}
