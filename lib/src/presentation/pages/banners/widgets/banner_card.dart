import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tarjeta de un aviso dentro del carrusel.
///
/// La tarjeta está **partida en dos**: la portada arriba y el texto abajo, sobre
/// una superficie sólida del tema.
///
/// **El texto no va encima de la foto.** Antes sí, sostenido por un degradado,
/// y eso hace que el contraste dependa de la imagen: sobre una foto clara la
/// fecha en blanco desaparece, y no hay degradado que lo arregle sin ensuciar
/// media portada. Sobre `surfaceContainerLow` el contraste sale del
/// `ColorScheme` y se resuelve solo en claro y en oscuro. De paso el título se
/// lee aunque la imagen no cargue, que era justo cuando peor se veía.
class BannerCard extends StatelessWidget {
  const BannerCard({
    super.key,
    required this.banner,
    required this.ancho,
    required this.onTap,
  });

  final BannerInfo banner;

  /// Ancho real de la tarjeta; se usa para pedir la imagen ya escalada.
  final double ancho;

  /// Abre el aviso completo.
  final VoidCallback onTap;

  /// Proporción de la portada (2:1). No incluye el bloque de texto.
  static const double relacionAspecto = 2 / 1;

  /// Líneas que se le conceden al título antes de recortarlo.
  static const int lineasTitulo = 2;

  /// Hueco entre la fecha y el título.
  static const double huecoTexto = 3;

  /// Altura de línea del título.
  ///
  /// Vive aquí y no suelta dentro del `build` porque el carrusel la necesita
  /// para calcular el alto de la tarjeta: si las dos se separan, el título se
  /// recorta o sobra hueco.
  static const double altoLineaTitulo = 1.3;

  /// Padding del bloque de texto.
  static const EdgeInsets paddingTexto = EdgeInsets.fromLTRB(14, 10, 14, 12);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // Sin esto, TalkBack y VoiceOver solo anuncian "imagen".
      label: '${AppStrings.bannersVerAviso}: ${banner.titulo}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            // Confirmación táctil: el usuario sabe que el toque entró antes de
            // que el sheet termine de abrirse.
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La portada se queda con todo el alto que sobre; el bloque de
              // texto toma el suyo, que es fijo.
              Expanded(child: _buildPortada(context)),
              _buildTexto(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Portada con la píldora de "Nuevo" encima, cuando toca.
  Widget _buildPortada(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImagen(context),
        if (banner.esReciente)
          Positioned(top: 10, left: 10, child: _buildPildoraNuevo(context)),
      ],
    );
  }

  /// Portada, decodificada al ancho real de la tarjeta.
  Widget _buildImagen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return CachedNetworkImage(
      imageUrl: banner.imagenUrl,
      fit: BoxFit.cover,
      // Clave para la memoria: sin esto, un JPEG de 1200 px se decodifica
      // completo en RAM aunque se pinte a 322. Se multiplica por el ratio de
      // píxeles para no perder nitidez en pantallas Retina.
      memCacheWidth: (ancho * dpr).round(),
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          ColoredBox(color: colorScheme.surfaceContainerHighest),
      // Si la imagen no carga, la tarjeta no se rompe: el título y la fecha
      // viven abajo, sobre superficie sólida, y siguen leyéndose igual.
      errorWidget: (context, url, error) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
          semanticLabel: AppStrings.bannersImagenNoDisponible,
        ),
      ),
    );
  }

  /// Fecha y título, sobre la superficie del tema.
  Widget _buildTexto(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: paddingTexto,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.fecha.isNotEmpty) _buildFecha(theme),
          Text(
            banner.titulo,
            maxLines: lineasTitulo,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: altoLineaTitulo,
            ),
          ),
        ],
      ),
    );
  }

  /// Fecha de publicación, con las mismas cifras tabulares que los pagos.
  Widget _buildFecha(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: huecoTexto),
      child: Text(
        banner.fecha,
        maxLines: 1,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Píldora que señala un aviso recién publicado.
  ///
  /// Mismo lenguaje que el chip de estado de los pagos —punto de color más
  /// palabra escrita—, para que la app no invente un componente nuevo por cada
  /// cosa que hay que destacar. Va sobre `surface` porque cae encima de la foto
  /// y necesita despegarse de ella.
  Widget _buildPildoraNuevo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppStrings.bannersNuevo,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
