import 'package:flutter/material.dart';

/// Cabecera con la información del usuario logueado.
///
/// Es **compacta a propósito**: el avatar a la izquierda y, a su derecha, el
/// nombre y debajo el email. Antes iba en vertical —avatar, nombre y email uno
/// bajo otro, con 24 de padding— y se llevaba casi un tercio de la pantalla,
/// dejando al menú sin sitio para sus renglones.
///
/// **El nombre nunca pasa de una línea.** Un nombre completo largo se encoge
/// hasta caber en vez de partirse en dos renglones o cortarse con puntos
/// suspensivos: se lee entero, que es de lo que se trata, y la cabecera conserva
/// siempre el mismo alto, así que el menú no baila según de quién sea la sesión.
///
/// Compatible con tema claro y oscuro.
class UserHeader extends StatelessWidget {
  /// Nombre del usuario.
  final String nombre;

  /// Email del usuario (opcional).
  final String? email;

  const UserHeader({
    super.key,
    required this.nombre,
    this.email,
  });

  /// Radio del avatar.
  static const double _radioAvatar = 26;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(colorScheme),
          const SizedBox(width: 14),
          Expanded(child: _buildDatos(theme, colorScheme)),
        ],
      ),
    );
  }

  /// Inicial del usuario dentro del círculo.
  Widget _buildAvatar(ColorScheme colorScheme) {
    return CircleAvatar(
      radius: _radioAvatar,
      backgroundColor: colorScheme.onPrimary,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  /// Nombre en una línea y, debajo, el email.
  Widget _buildDatos(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `FittedBox` y no `ellipsis`: el nombre completo se lee entero,
        // encogido si hace falta, en lugar de quedar cortado a media palabra.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nombre,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            email!,
            maxLines: 1,
            // El email sí se recorta: es un dato de apoyo y encogerlo más lo
            // dejaría ilegible.
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
