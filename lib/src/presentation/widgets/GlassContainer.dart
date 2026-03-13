import 'package:flutter/material.dart';

/// Contenedor con efecto glass (vidrio esmerilado).
///
/// Se utiliza principalmente en formularios de autenticación
/// para crear un efecto visual moderno sobre fondos con imagen.
///
/// Características:
/// - Fondo semi-transparente con blur
/// - Bordes redondeados
/// - Dimensiones responsivas basadas en el tamaño de pantalla
///
/// Ejemplo de uso:
/// ```dart
/// GlassContainer(
///   child: Column(
///     children: [
///       Text('Mi formulario'),
///       TextField(),
///     ],
///   ),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  /// Widget hijo que se muestra dentro del contenedor.
  final Widget child;

  /// Factor de ancho relativo al ancho de pantalla (0.0 a 1.0).
  /// Por defecto es 0.85 (85% del ancho).
  final double widthFactor;

  /// Factor de alto relativo al alto de pantalla (0.0 a 1.0).
  /// Por defecto es 0.75 (75% del alto).
  /// Si es null, el alto se ajusta al contenido.
  final double? heightFactor;

  /// Color de fondo del contenedor.
  /// Por defecto es blanco con 25% de opacidad.
  final Color backgroundColor;

  /// Radio de los bordes redondeados.
  /// Por defecto es 50.
  final double borderRadius;

  /// Padding interno del contenedor.
  /// Por defecto es 20 en todos los lados.
  final EdgeInsetsGeometry padding;

  /// Si el contenido debe ser scrollable.
  /// Por defecto es true.
  final bool scrollable;

  /// Ancho máximo del contenedor (útil para tablets).
  /// Por defecto es 500.
  final double maxWidth;

  /// Alto máximo del contenedor (útil para tablets).
  /// Por defecto es 700.
  final double? maxHeight;

  const GlassContainer({
    super.key,
    required this.child,
    this.widthFactor = 0.85,
    this.heightFactor = 0.75,
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.25),
    this.borderRadius = 50,
    this.padding = const EdgeInsets.all(20),
    this.scrollable = true,
    this.maxWidth = 500,
    this.maxHeight = 700,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Calcular dimensiones con límites máximos para tablets
    final calculatedWidth = (size.width * widthFactor).clamp(0.0, maxWidth);
    final calculatedHeight = heightFactor != null
        ? (size.height * heightFactor!).clamp(0.0, maxHeight ?? double.infinity)
        : null;

    return Container(
      width: calculatedWidth,
      height: calculatedHeight,
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      child: scrollable
          ? SingleChildScrollView(
              child: child,
            )
          : child,
    );
  }
}
