import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ListTile que copia su valor al portapapeles al ser tocado.
///
/// Muestra un ícono, label y valor. Al tocar, copia el valor
/// al portapapeles y muestra un SnackBar de confirmación.
class CopyableListTile extends StatelessWidget {
  /// Ícono a mostrar a la izquierda.
  final IconData icon;

  /// Etiqueta descriptiva del campo.
  final String label;

  /// Valor a mostrar y copiar.
  final String value;

  const CopyableListTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.copy,
        size: 16,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      onTap: () => _copyToClipboard(context),
    );
  }

  /// Copia el valor al portapapeles y muestra feedback.
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
