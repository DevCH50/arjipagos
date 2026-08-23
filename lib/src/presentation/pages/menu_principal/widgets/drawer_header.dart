import 'package:flutter/material.dart';

/// Header del drawer con avatar y nombre de pila del usuario.
///
/// Muestra un gradiente con el color primario del tema,
/// compatible con tema claro y oscuro.
/// Incluye SafeArea top para iOS con notch.
///
/// No lleva correo ni nombre completo a propósito: el header es una
/// identificación breve, y los apellidos y el email solo lo recargaban.
class UserDrawerHeader extends StatelessWidget {
  /// Nombre de pila del usuario, sin apellidos.
  final String nombre;

  const UserDrawerHeader({
    super.key,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores adaptables al tema
    final gradientStart = colorScheme.primary;
    final gradientEnd = colorScheme.primary.withValues(alpha: 0.7);
    final textColor = colorScheme.onPrimary;

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
          // El nombre va a la derecha del avatar, no debajo: ocupa menos alto
          // y deja más sitio a la lista de datos en pantallas cortas.
          child: Row(
            children: [
              // Avatar con la inicial del nombre
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
              const SizedBox(width: 16),
              // Nombre de pila. Va en Expanded para que un nombre largo se
              // recorte en vez de desbordar la fila.
              Expanded(
                child: Text(
                  nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
