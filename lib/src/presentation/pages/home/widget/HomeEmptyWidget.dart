import 'package:flutter/material.dart';

/// Widget que muestra el estado vacío de la página Home.
///
/// Se presenta cuando no hay alumnos registrados en el sistema,
/// ofreciendo un botón para actualizar la lista.
///
/// Compatible con tema claro y oscuro.
class HomeEmptyWidget extends StatelessWidget {
  /// Callback que se ejecuta al presionar el botón de actualizar.
  final VoidCallback onRefresh;

  const HomeEmptyWidget({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay Alumnos registrados',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
