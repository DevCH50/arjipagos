import 'package:arjipagos/src/presentation/pages/banners/widgets/banner_card.dart';
import 'package:flutter/material.dart';

/// Marcador de posición mientras se descargan los avisos.
///
/// Reserva exactamente el mismo espacio que ocupará el carrusel, de modo que
/// el menú **no dé un salto** cuando llegue el contenido. Es estático a
/// propósito: una animación de brillo obligaría a mantener un controlador vivo
/// en la pantalla de entrada de la app, y el gasto no compensa para algo que
/// dura menos de un segundo.
class BannersSkeleton extends StatelessWidget {
  const BannersSkeleton({
    super.key,
    required this.ancho,
    required this.alto,
  });

  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: alto,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTarjeta(colorScheme),
          const SizedBox(width: 12),
          _buildTarjeta(colorScheme),
        ],
      ),
    );
  }

  /// Silueta con la forma y el tamaño exactos de una tarjeta real.
  ///
  /// Repite la anatomía partida de la tarjeta —portada arriba, bloque de texto
  /// abajo— en vez de ser un rectángulo liso: así lo que aparece al llegar los
  /// datos es lo que el hueco venía prometiendo.
  Widget _buildTarjeta(ColorScheme colorScheme) {
    return Container(
      width: ancho,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: const SizedBox(width: double.infinity),
            ),
          ),
          Padding(
            padding: BannerCard.paddingTexto,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarra(colorScheme, ancho: 72, alto: 10),
                const SizedBox(height: 6),
                _buildBarra(colorScheme, ancho: ancho * 0.6, alto: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barra que hace de renglón de texto.
  Widget _buildBarra(
    ColorScheme colorScheme, {
    required double ancho,
    required double alto,
  }) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
