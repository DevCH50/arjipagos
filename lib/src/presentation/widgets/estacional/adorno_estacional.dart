import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/motivo_estacional_painter.dart';
import 'package:flutter/material.dart';

/// El motivo de la temporada, suelto.
///
/// Es la pieza reutilizable: la usan el splash, la tirilla de avisos y, por
/// dentro, [ListonEstacional]. Así el `CustomPaint` y la etiqueta de
/// accesibilidad están escritos **una sola vez** aunque el adorno salga en tres
/// pantallas distintas.
///
/// **Fuera de temporada no ocupa nada.** Devuelve un `SizedBox.shrink()`, así
/// que quien lo monte no tiene que preguntar en qué mes está: siete meses al año
/// es como si no estuviera puesto.
///
/// Se llama «adorno» y no «motivo» para no chocar con el enum
/// [MotivoEstacional], que es lo que este widget dibuja.
class AdornoEstacional extends StatelessWidget {
  /// Alto del adorno.
  ///
  /// El motivo se escala a lo que le den: 15 px en el listón del menú, más en el
  /// splash, y del alto de una línea de texto junto a «Avisos».
  final double alto;

  /// Ancho. Sin él ocupa todo el que le den, que es lo normal en un listón.
  /// Se fija solo cuando el adorno acompaña a un texto.
  final double? ancho;

  /// Cuánto se transparenta.
  ///
  /// El splash lo baja bastante: allí el motivo tiene que sugerir el mes sin
  /// competir con el logo, que es lo que el usuario está mirando.
  final double opacidad;

  const AdornoEstacional({
    super.key,
    this.alto = 15,
    this.ancho,
    this.opacidad = 1,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final DecoracionEstacional? decoracion =
        tema.extension<DecoracionEstacional>();

    // Sin extensión —un `ThemeData` armado a mano en un test— o fuera de
    // temporada, no se pinta nada.
    if (decoracion == null || !decoracion.hayDecoracion) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: decoracion.etiquetaAccesible,
      // Es decoración: se anuncia una vez y no se entra a recorrerla.
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        width: ancho ?? double.infinity,
        child: CustomPaint(
          painter: MotivoEstacionalPainter(
            motivo: decoracion.motivo,
            colores: decoracion.colores,
            // El hilo del papel picado sale del tema, no de la temporada: así
            // se ve tanto sobre el fondo claro como sobre el oscuro.
            colorTrazo: tema.colorScheme.onSurfaceVariant,
            opacidad: opacidad,
          ),
        ),
      ),
    );
  }
}
