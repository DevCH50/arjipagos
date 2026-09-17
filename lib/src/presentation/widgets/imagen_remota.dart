import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Imagen descargada de la red, con hueco visible y progreso mientras carga.
///
/// **Por qué existe:** hasta el 2026-09-17 las portadas de los avisos usaban
/// `CachedNetworkImage` con un `placeholder` que era un rectángulo de color
/// liso. Mientras la imagen bajaba no se veía absolutamente nada —ni forma ni
/// movimiento—, y como la portada del último aviso pesa 300 KB, el hueco se
/// quedaba vacío varios segundos: parecía que la imagen estaba rota.
///
/// Aquí el hueco dice dos cosas a la vez: **qué va a aparecer** (la silueta de
/// una imagen) y **que está en camino** (el aro de progreso girando). Cuando el
/// servidor manda el tamaño total, el aro deja de girar en seco y marca el
/// porcentaje real.
class ImagenRemota extends StatelessWidget {
  const ImagenRemota({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.anchoEnCache,
  });

  /// Dirección de la imagen.
  final String url;

  final BoxFit fit;

  /// Ancho al que decodificar, en píxeles físicos.
  ///
  /// Sin esto, un JPEG de 1200 px se decodifica entero en RAM aunque se pinte a
  /// 322. Se pasa tal cual a `memCacheWidth`.
  final int? anchoEnCache;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: anchoEnCache,
      fadeInDuration: const Duration(milliseconds: 200),
      // `progressIndicatorBuilder` en vez de `placeholder`: es el único que
      // recibe cuánto se lleva descargado. No se pueden usar los dos.
      progressIndicatorBuilder: (context, url, progreso) =>
          ImagenRemotaCargando(progreso: progreso.progress),
      errorWidget: (context, url, error) => const ImagenRemotaError(),
    );
  }
}

/// El hueco de una imagen que todavía está bajando.
///
/// Es público para poder probarlo suelto: montar un `CachedNetworkImage` en un
/// test exigiría una caché falsa, y lo que importa aquí es lo que ve el usuario.
class ImagenRemotaCargando extends StatelessWidget {
  const ImagenRemotaCargando({super.key, this.progreso});

  /// Fracción descargada, de 0 a 1. En `null` el aro gira sin marcar avance,
  /// que es lo que toca mientras no se sepa el tamaño total.
  final double? progreso;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colores.surfaceContainerHighest,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // La silueta dice qué se está esperando. Va tenue a propósito: es
            // el hueco, no el contenido.
            Icon(
              Icons.image_outlined,
              size: 44,
              color: colores.onSurfaceVariant.withValues(alpha: 0.35),
              semanticLabel: AppStrings.bannersImagenCargando,
            ),
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: progreso,
                strokeWidth: 2.5,
                color: colores.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El hueco de una imagen que no se pudo cargar.
///
/// No se reintenta solo ni se pinta un botón: la tarjeta sigue siendo
/// pulsable y el texto del aviso vive fuera de la imagen, así que se lee igual.
class ImagenRemotaError extends StatelessWidget {
  const ImagenRemotaError({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colores.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 44,
          color: colores.onSurfaceVariant,
          semanticLabel: AppStrings.bannersImagenNoDisponible,
        ),
      ),
    );
  }
}
