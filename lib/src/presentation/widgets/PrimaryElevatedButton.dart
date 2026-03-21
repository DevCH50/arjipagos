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
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = color ?? colorScheme.primary;
    // Si usa color personalizado, texto oscuro; si usa el tema, usa onPrimary
    final textColor = color != null ? Colors.black54 : colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(text, style: TextStyle(fontSize: 18, color: textColor)),
    );
  }
}
