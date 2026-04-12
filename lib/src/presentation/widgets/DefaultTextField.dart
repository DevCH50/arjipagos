import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Campo de texto genérico reutilizable con soporte para tema claro y oscuro.
///
/// Por defecto usa colores blancos (para fondos con imagen o dark, como Login).
/// Pasar [useThemeColors] = true para usar los colores del tema activo
/// (tema claro u oscuro estándar, como en CambiarContrasena).
class DefaultTextField extends StatefulWidget {
  final String label;
  final String? errorText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String text) onChanged;
  final String? Function(String?)? validator;

  /// Si es true, los colores se toman del tema activo (claro u oscuro).
  /// Si es false (por defecto), usa Colors.white — para fondos oscuros/imagen.
  final bool useThemeColors;

  // Parámetros para personalizar el estilo del error (aplican en modo dark/imagen)
  final Color errorColor;
  final double errorFontSize;
  final FontWeight errorFontWeight;
  final int errorMaxLines;
  final Color errorBorderColor;
  final bool errorWithShadow;

  const DefaultTextField({
    super.key,
    required this.label,
    required this.icon,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
    this.validator,
    this.useThemeColors = false,
    // Valores por defecto para fondos oscuros/imagen
    this.errorColor = Colors.yellowAccent,
    this.errorFontSize = 14.0,
    this.errorFontWeight = FontWeight.w500,
    this.errorMaxLines = 2,
    this.errorBorderColor = Colors.yellowAccent,
    this.errorWithShadow = true,
  });

  @override
  State<DefaultTextField> createState() => _DefaultTextFieldState();
}

class _DefaultTextFieldState extends State<DefaultTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useThemeColors) {
      return _buildWithThemeColors(context);
    }
    return _buildWithWhiteColors();
  }

  /// Campo con colores del tema activo (compatible con claro y oscuro).
  Widget _buildWithThemeColors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      onChanged: widget.onChanged,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      style: TextStyle(color: colorScheme.onSurface),
      cursorColor: colorScheme.primary,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: widget.errorMaxLines,
        prefixIcon: Icon(widget.icon, color: colorScheme.onSurfaceVariant),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: _togglePasswordVisibility,
                tooltip: _obscureText ? AppStrings.mostrarContrasena : AppStrings.ocultarContrasena,
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
    );
  }

  /// Campo con colores blancos para fondos oscuros o con imagen (Login, Register).
  Widget _buildWithWhiteColors() {
    return TextFormField(
      onChanged: widget.onChanged,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        filled: false,
        label: Text(widget.label, style: const TextStyle(color: Colors.white)),
        errorText: widget.errorText,
        errorStyle: TextStyle(
          color: widget.errorColor,
          fontSize: widget.errorFontSize,
          fontWeight: widget.errorFontWeight,
          shadows: widget.errorWithShadow
              ? [
                  const Shadow(
                    color: Colors.black87,
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        errorMaxLines: widget.errorMaxLines,
        prefixIcon: Icon(widget.icon, color: Colors.white),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: _togglePasswordVisibility,
                tooltip: _obscureText ? AppStrings.mostrarContrasena : AppStrings.ocultarContrasena,
              )
            : null,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.errorBorderColor),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.errorBorderColor, width: 2),
        ),
      ),
    );
  }
}


// ─── Referencia de configuración por contexto ───────────────────────────────
//
// Para fondos Oscuros / con imagen (Login, Register):
//   useThemeColors: false   ← default
//   errorColor: Colors.yellowAccent
//   errorFontSize: 14.0
//   errorFontWeight: FontWeight.w600
//   errorWithShadow: true
//
// Para fondos Claros (Scaffold normal, CambiarContrasena, etc.):
//   useThemeColors: true    ← usa colores del tema activo automáticamente
//
// ────────────────────────────────────────────────────────────────────────────
