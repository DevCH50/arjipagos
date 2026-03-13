import 'package:flutter/material.dart';

/// Header que muestra la información del usuario logueado.
///
/// Usado en el body principal del MenuPrincipal.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores adaptables al tema
    final gradientStart = colorScheme.primary;
    final gradientEnd = colorScheme.primary.withValues(alpha: 0.8);
    final textColor = colorScheme.onPrimary;
    final subtitleColor = colorScheme.onPrimary.withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.onPrimary,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nombre
          Text(
            nombre,
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Email
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
