import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget que muestra un enlace para información de cuentas.
///
/// Compatible con tema claro y oscuro.
/// - [color]: color de acento (icono y botón). Por defecto usa [ColorScheme.primary].
/// - [textColor]: color del texto del enlace. Por defecto usa [ColorScheme.onSurface].
///   Pasar [Colors.white] cuando el widget esté sobre un fondo oscuro/imagen.
class NoTienesCuentaAun extends StatelessWidget {
  final Color? color;
  final Color? textColor;
  final String mensaje;
  final String titulo;
  final IconData icono;

  const NoTienesCuentaAun({
    super.key,
    this.color,
    this.textColor,
    required this.mensaje,
    required this.titulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    final linkColor = textColor ?? theme.colorScheme.primary;

    return TextButton(
      style: TextButton.styleFrom(foregroundColor: linkColor),
      onPressed: () => _showInfoDialog(context, theme, accentColor),
      child: Text(titulo),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme, Color accentColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 60, color: accentColor),
                const SizedBox(height: 16),
                Text(
                  AppStrings.noTienesCuentaAtencion,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(AppStrings.understood),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
