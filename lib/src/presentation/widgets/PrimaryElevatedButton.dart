import 'package:flutter/material.dart';

/// Botón primario elevado reutilizable.
///
/// Usa el color primario del tema (cafecito) por defecto.
/// Se puede sobreescribir con [color] para casos especiales.
class PrimaryElevatedButton extends StatelessWidget {
  final String text;
  final Color? color; // null = usa el color primario del tema
  final Function() onPressed;

  const PrimaryElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = color ?? colorScheme.primary;
    // Calcula texto legible según la luminancia del fondo
    final textColor = color != null
        ? (color!.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(fontSize: 18, color: textColor),
      ),
    );
  }
}
