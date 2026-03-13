import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget que muestra el avatar de un usuario.
///
/// Puede mostrar una imagen de red con caché o las iniciales
/// del nombre si no hay imagen disponible.
///
/// Compatible con tema claro y oscuro.
class UserAvatar extends StatelessWidget {
  /// URL de la foto del usuario (opcional).
  final String? urlPhoto;

  /// Nombre del usuario para mostrar inicial si no hay foto.
  final String nombre;

  /// Indica si el usuario está dado de baja (cambia colores).
  final bool esBaja;

  /// Radio del avatar circular.
  final double radius;

  /// Si debe mostrar borde alrededor del avatar.
  final bool showBorder;

  /// Si debe mostrar indicador de estado online.
  final bool showOnlineIndicator;

  /// Si el usuario está online.
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.urlPhoto,
    required this.nombre,
    this.esBaja = false,
    this.radius = 24,
    this.showBorder = false,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores adaptables al tema
    final backgroundColor = esBaja
        ? AppColors.getAlumnoBajaBackground(isDark)
        : AppColors.getAlumnoActivoBackground(isDark);
    final textColor = esBaja
        ? AppColors.getAlumnoBajaText(isDark)
        : AppColors.getAlumnoActivoText(isDark);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: _buildAvatarContent(context, textColor),
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : Theme.of(context).colorScheme.outline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Construye el contenido del avatar (imagen o inicial).
  Widget _buildAvatarContent(BuildContext context, Color textColor) {
    // Si no hay URL o está vacía, mostrar inicial
    if (urlPhoto == null || urlPhoto!.isEmpty) {
      return _buildInitial(textColor);
    }

    // Cargar imagen con caché
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: urlPhoto!,
        fit: BoxFit.cover,
        // Mientras carga
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: radius,
            height: radius,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
        ),
        // Si hay error, mostrar inicial
        errorWidget: (context, url, error) => _buildInitial(textColor),
      ),
    );
  }

  /// Construye el widget con la inicial del nombre.
  Widget _buildInitial(Color textColor) {
    return Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
      ),
    );
  }
}
