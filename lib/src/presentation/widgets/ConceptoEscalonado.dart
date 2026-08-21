import 'package:flutter/material.dart';

/// Concepto de un pago, pintado en el escalón de texto más grande que lo deje
/// caber en **una sola línea**.
///
/// La rampa son los tamaños de cuerpo del tema —`bodyLarge`, `bodyMedium`,
/// `bodySmall` de Material 3—, no números escritos a mano: se baja de escalón
/// solo cuando el string medido no cabe, y nunca por debajo del último.
///
/// **Por qué se mide y no se estima:** el ancho real de un texto depende de la
/// tipografía, del `letterSpacing` del tema y de la escala de fuente que el
/// usuario tenga puesta en el sistema. Un cálculo por número de caracteres se
/// equivoca justo en los conceptos largos, que son los que importan. Aquí se
/// mide con `TextPainter`, es decir con el mismo motor que luego lo pinta.
///
/// **Si ni el escalón más chico cabe** el texto pasa a dos líneas en vez de
/// recortarse: la regla es que el concepto se lea completo, y un concepto
/// cortado con puntos suspensivos no cumple esa regla.
class ConceptoEscalonado extends StatelessWidget {
  const ConceptoEscalonado({
    super.key,
    required this.texto,
    this.color,
  });

  /// Concepto tal como se pinta; es también el que se mide.
  final String texto;

  /// Color del texto; por omisión, el del tema para contenido sobre superficie.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final escalones = _escalones(theme);

    return LayoutBuilder(
      builder: (context, restricciones) {
        final elegido = _elegir(
          escalones,
          restricciones.maxWidth,
          MediaQuery.textScalerOf(context),
          Directionality.of(context),
        );

        return Text(
          texto,
          // Dos líneas solo en el caso extremo en que ni el escalón más chico
          // alcance; en todo lo demás, una línea exacta.
          maxLines: elegido.cabe ? 1 : 2,
          style: elegido.estilo,
        );
      },
    );
  }

  /// Rampa de escalones del tema, ya con el peso y el color del concepto.
  List<TextStyle> _escalones(ThemeData theme) {
    final colorTexto = color ?? theme.colorScheme.onSurface;

    return <TextStyle>[
      theme.textTheme.bodyLarge!,
      theme.textTheme.bodyMedium!,
      theme.textTheme.bodySmall!,
    ]
        .map((estilo) => estilo.copyWith(
              fontWeight: FontWeight.w500,
              color: colorTexto,
            ))
        .toList(growable: false);
  }

  /// Primer escalón en el que el concepto cabe entero en una línea.
  ///
  /// Devuelve además si llegó a caber, para decidir el número de líneas sin
  /// tener que volver a medir.
  ({TextStyle estilo, bool cabe}) _elegir(
    List<TextStyle> escalones,
    double disponible,
    TextScaler escalador,
    TextDirection direccion,
  ) {
    // Sin un ancho acotado no hay nada contra qué medir: se queda en el
    // escalón grande, que es el que manda mientras no se demuestre que estorba.
    if (!disponible.isFinite) {
      return (estilo: escalones.first, cabe: true);
    }

    for (final estilo in escalones) {
      if (_mide(estilo, escalador, direccion) <= disponible) {
        return (estilo: estilo, cabe: true);
      }
    }

    return (estilo: escalones.last, cabe: false);
  }

  /// Ancho que ocupa el concepto con un estilo dado, en una sola línea.
  double _mide(TextStyle estilo, TextScaler escalador, TextDirection direccion) {
    final pintor = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      maxLines: 1,
      textDirection: direccion,
      textScaler: escalador,
    )..layout();

    final ancho = pintor.width;
    // Sin esto queda retenida la memoria nativa del párrafo medido, y aquí se
    // mide una vez por renglón en cada relayout de la lista.
    pintor.dispose();

    return ancho;
  }
}
