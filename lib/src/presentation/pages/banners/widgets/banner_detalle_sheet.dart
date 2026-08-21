import 'package:arjipagos/src/core/utils/contenido_a_html.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// Hoja inferior con el aviso completo.
///
/// **Por qué una hoja y no un diálogo centrado:** para contenido largo con
/// desplazamiento, la hoja inferior es la convención en las dos plataformas
/// —*sheet* en las HIG de Apple, *modal bottom sheet* en Material 3—. Además
/// se cierra arrastrando hacia abajo, un gesto que cae en la zona cómoda del
/// pulgar, mientras que el botón de cerrar de un diálogo centrado queda en la
/// esquina superior, la más difícil de alcanzar con una mano. La app ya usa
/// este mismo patrón para el detalle de las notificaciones.
///
/// Se abre con [mostrarBannerDetalle].
class BannerDetalleSheet extends StatelessWidget {
  const BannerDetalleSheet({super.key, required this.banner});

  final BannerInfo banner;

  /// Proporción de la portada dentro de la hoja (16:9, la del formato foto).
  static const double _relacionPortada = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // viewPaddingOf: inset físico real del sistema (home indicator en iOS,
    // barra de gestos en Android), consistente aunque un widget padre ya haya
    // consumido el padding.
    final double margenInferior = 24 + MediaQuery.viewPaddingOf(context).bottom;

    return ConstrainedBox(
      // La hoja se ajusta al contenido y nunca tapa la pantalla completa: ver
      // el menú detrás le recuerda al usuario que esto se cierra.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        maxWidth: 640,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBarra(context, theme),
          Flexible(
            child: _BannerDetalleContenido(
              banner: banner,
              relacionPortada: _relacionPortada,
              margenInferior: margenInferior,
            ),
          ),
        ],
      ),
    );
  }

  /// Asa de arrastre.
  ///
  /// Es el único control de cierre, y es el nativo: en iOS el *grabber* y en
  /// Material 3 el *drag handle* significan exactamente lo mismo, así que no
  /// hace falta enseñarle nada al usuario. Un botón de cerrar encima competiría
  /// con un gesto que la gente ya conoce.
  Widget _buildBarra(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 4,
      width: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Contenido desplazable de la hoja: portada, título, fecha y cuerpo.
class _BannerDetalleContenido extends StatelessWidget {
  const _BannerDetalleContenido({
    required this.banner,
    required this.relacionPortada,
    required this.margenInferior,
  });

  final BannerInfo banner;
  final double relacionPortada;
  final double margenInferior;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (banner.tieneImagen) _buildPortada(context),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, margenInferior),
            child: _buildTexto(Theme.of(context)),
          ),
        ],
      ),
    );
  }

  /// Portada con relación de aspecto fija: el alto no salta al cargar y el
  /// encuadre es el mismo en todos los dispositivos.
  Widget _buildPortada(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double ancho = MediaQuery.sizeOf(context).width;
    final double dpr = MediaQuery.devicePixelRatioOf(context);

    return AspectRatio(
      aspectRatio: relacionPortada,
      child: CachedNetworkImage(
        imageUrl: banner.imagenUrl,
        fit: BoxFit.cover,
        // Se decodifica al ancho de pantalla, no al de la imagen original.
        memCacheWidth: (ancho * dpr).round(),
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) =>
            ColoredBox(color: colorScheme.surfaceContainerHighest),
        // Si la portada falla, el aviso se lee igual.
        errorWidget: (context, url, error) =>
            ColoredBox(color: colorScheme.surfaceContainerHighest),
      ),
    );
  }

  /// Título, fecha y cuerpo de la nota.
  Widget _buildTexto(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          banner.titulo,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            height: 1.25,
          ),
        ),
        if (banner.fecha.isNotEmpty) const SizedBox(height: 8),
        if (banner.fecha.isNotEmpty)
          Text(
            banner.fecha,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 16),
        Divider(color: theme.colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 16),
        HtmlWidget(
          contenidoAHtml(banner.cuerpo, banner.formato),
          // Interlineado de lectura: el cuerpo es una nota, no una etiqueta.
          // El color sale del tema, así que se lee igual en claro y en oscuro
          // sin que el backend tenga que saber nada del tema.
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Abre la hoja con el aviso completo.
///
/// Se cierra arrastrando hacia abajo, con el botón atrás del sistema o tocando
/// fuera de la hoja: tres salidas, todas estándar en Android y en iOS.
Future<void> mostrarBannerDetalle(BuildContext context, BannerInfo banner) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // useSafeArea evita que la hoja quede bajo la barra de estado cuando el
    // contenido es largo y crece hasta arriba.
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    builder: (_) => BannerDetalleSheet(banner: banner),
  );
}
