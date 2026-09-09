import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:flutter/material.dart';

/// Franja con los colores de la temporada, en degradado.
///
/// Es la pieza más discreta de la decoración y la que se puede poner en
/// cualquier sitio: no dibuja nada, solo colorea. La usan el listón del menú
/// —de lado a lado, bajo la cabecera— y el rótulo de «Avisos», donde va corta y
/// redondeada, como una cinta.
///
/// **Degradado y no tres bloques.** Tres bloques verticales en septiembre serían
/// una bandera mexicana en miniatura, y la bandera tiene reglas de uso que una
/// app de pagos no debería andar rozando. El degradado evoca los colores sin
/// representar ni el escudo ni las proporciones.
///
/// Fuera de temporada no ocupa nada.
class FranjaEstacional extends StatelessWidget {
  /// Alto de la franja.
  final double alto;

  /// Ancho. Sin él ocupa todo el disponible.
  final double? ancho;

  /// Redondeo de las puntas. Se usa cuando la franja va suelta junto a un
  /// texto: con las puntas cuadradas parece un trozo cortado de algo.
  final BorderRadius? radio;

  const FranjaEstacional({
    super.key,
    this.alto = 3,
    this.ancho,
    this.radio,
  });

  @override
  Widget build(BuildContext context) {
    final DecoracionEstacional? decoracion =
        Theme.of(context).extension<DecoracionEstacional>();

    if (decoracion == null || !decoracion.hayDecoracion) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: alto,
      width: ancho ?? double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: decoracion.colores),
          borderRadius: radio,
        ),
      ),
    );
  }
}
