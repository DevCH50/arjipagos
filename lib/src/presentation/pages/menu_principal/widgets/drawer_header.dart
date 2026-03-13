import 'package:flutter/material.dart';

/// Header del drawer con avatar y nombre del usuario.
///
/// Muestra un gradiente con el color primario del tema,
/// compatible con tema claro y oscuro.
/// Incluye SafeArea top para iOS con notch.
class UserDrawerHeader extends StatelessWidget {
  /// Nombre del usuario a mostrar.
  final String nombre;

  /// Email del usuario (opcional).
  final String? email;

  const UserDrawerHeader({
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
    final gradientEnd = colorScheme.primary.withValues(alpha: 0.7);
    final textColor = colorScheme.onPrimary;
    final subtitleColor = colorScheme.onPrimary.withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.onPrimary,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Nombre
              Text(
                nombre,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Email
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
