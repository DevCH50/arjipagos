import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar una imagen de fondo con overlay.
///
/// Se utiliza principalmente en las pantallas de autenticación
/// (login, registro) para proporcionar un fondo visual atractivo.
///
/// Ejemplo de uso:
/// ```dart
/// Stack(
///   children: [
///     const BackgroundImage(),
///     // ... otros widgets
///   ],
/// )
/// ```
class BackgroundImage extends StatelessWidget {
  /// Ruta del asset de la imagen.
  final String assetPath;

  /// Color del overlay que se aplica sobre la imagen.
  /// Por defecto es negro con 54% de opacidad.
  final Color overlayColor;

  /// Modo de mezcla para el overlay.
  /// Por defecto es [BlendMode.darken].
  final BlendMode blendMode;

  /// Ajuste de la imagen dentro del contenedor.
  /// Por defecto es [BoxFit.cover].
  final BoxFit fit;

  const BackgroundImage({
    super.key,
    this.assetPath = 'assets/img/background_shopping.jpg',
    this.overlayColor = AppColors.authBackgroundOverlay,
    this.blendMode = BlendMode.darken,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Image.asset(
      assetPath,
      fit: fit,
      width: size.width,
      height: size.height,
      color: overlayColor,
      colorBlendMode: blendMode,
    );
  }
}
