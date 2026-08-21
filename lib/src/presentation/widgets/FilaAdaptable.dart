import 'package:flutter/material.dart';

/// Fila de dos datos que se apila cuando el de la derecha no cabe al lado.
///
/// Mide el texto de la derecha con su estilo y con la escala de fuente que el
/// usuario tenga puesta en el sistema. Si necesita más de la mitad del ancho
/// disponible, el dato baja a su propia línea: así el de la izquierda —el
/// concepto, la fecha o el chip de estado— nunca se recorta ni desborda, y en
/// pantallas normales los dos siguen en la misma línea, que es como mejor se
/// leen.
///
/// No hay ninguna medida escrita a mano: el ancho lo da el `LayoutBuilder`, el
/// tamaño de letra el tema y la escala el `MediaQuery`.
///
/// La comparten los renglones de pago de **Pagos Pendientes** y del
/// **Carrito**, para que las dos pantallas se lean igual.
class FilaAdaptable extends StatelessWidget {
  /// Dato principal; ocupa el espacio sobrante de la fila.
  ///
  /// Si es una píldora o un botón —algo que no deba estirarse— conviene
  /// envolverlo en un `Align`, porque aquí va dentro de un `Expanded`.
  final Widget izquierda;

  /// Dato secundario, alineado a la derecha.
  final Widget derecha;

  /// Texto del dato secundario, tal como se pinta; solo se usa para medirlo.
  final String textoDerecha;

  /// Estilo con el que se pinta el dato secundario; el mismo que se mide.
  final TextStyle estiloDerecha;

  const FilaAdaptable({
    super.key,
    required this.izquierda,
    required this.derecha,
    required this.textoDerecha,
    required this.estiloDerecha,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (_necesitaApilarse(context, restricciones.maxWidth)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              izquierda,
              Align(alignment: Alignment.centerRight, child: derecha),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: izquierda),
            const SizedBox(width: 8),
            derecha,
          ],
        );
      },
    );
  }

  /// El dato de la derecha se queda con más de la mitad del ancho: al de la
  /// izquierda le quedaría tan poco que habría que encogerlo hasta hacerlo
  /// ilegible, así que es mejor darle a cada uno su línea.
  bool _necesitaApilarse(BuildContext context, double anchoDisponible) {
    if (!anchoDisponible.isFinite) {
      return false;
    }

    final pintor = TextPainter(
      text: TextSpan(text: textoDerecha, style: estiloDerecha),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return pintor.width > anchoDisponible / 2;
  }
}
