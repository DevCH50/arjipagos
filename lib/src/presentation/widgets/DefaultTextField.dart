import 'package:flutter/material.dart';

class DefaultTextField extends StatefulWidget {
  final String label;
  final String? errorText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String text) onChanged;
  final String? Function(String?)? validator;
  
  // ✅ Parámetros para personalizar el estilo del error
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
    // ✅ Valores por defecto personalizables
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
    return TextFormField(
      onChanged: (text) {
        widget.onChanged(text);
      },
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        filled: false,
        label: Text(widget.label, style: const TextStyle(color: Colors.white)),
        errorText: widget.errorText,
        // ✅ Estilo de error personalizable
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
                tooltip: _obscureText
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
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
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      obscureText: _obscureText,
    );
  }
}


// Para fondos Oscuros

// errorColor: Colors.yellowAccent,
// errorFontSize: 14.0,
// errorFontWeight: FontWeight.w600,
// errorWithShadow: true,


// Para fondos Claros

// errorColor: Colors.red.shade700,
// errorFontSize: 13.0,
// errorFontWeight: FontWeight.w500,
// errorWithShadow: false,


// Fondo con Imagen

// errorColor: Colors.white,
// errorFontSize: 15.0,
// errorFontWeight: FontWeight.bold,
// errorWithShadow: true,