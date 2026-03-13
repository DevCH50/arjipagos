import 'package:flutter/material.dart';

/// Encabezado de sección en el drawer.
///
/// Muestra un título con el color primario del tema.
class SectionHeader extends StatelessWidget {
  /// Título de la sección.
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
