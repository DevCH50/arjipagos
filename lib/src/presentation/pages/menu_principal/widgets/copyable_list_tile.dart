import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ListTile que copia su valor al portapapeles al ser tocado.
///
/// Muestra un ícono, label y valor. Al tocar, copia el valor
/// al portapapeles y muestra un check visual de confirmación
/// directamente en el tile (compatible con drawer abierto).
class CopyableListTile extends StatefulWidget {
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
  State<CopyableListTile> createState() => _CopyableListTileState();
}

class _CopyableListTileState extends State<CopyableListTile> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        widget.icon,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(
        widget.label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        widget.value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check,
                key: const ValueKey('check'),
                size: 16,
                color: colorScheme.primary,
              )
            : Icon(
                Icons.copy,
                key: const ValueKey('copy'),
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
      ),
      onTap: _copyToClipboard,
    );
  }
}
