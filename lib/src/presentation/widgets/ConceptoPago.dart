import 'package:flutter/material.dart';

/// Concepto de un pago, **siempre al mismo tamaño y siempre entero**.
///
/// ## Las dos reglas, y en qué orden mandan
///
/// 1. **El concepto se lee completo.** Nunca se recorta con puntos suspensivos
///    ni se abrevia. Es lo que le dice al usuario qué está pagando; un concepto
///    a medias no sirve para nada.
/// 2. **La tipografía es congruente entre renglones.** Todos los conceptos de
///    la lista se pintan con el mismo escalón del tema (`bodyLarge`), y el
///    importe va de ese mismo tamaño en negrita. El importe destaca por peso y
///    color, no por ser más grande.
///
/// Cuando el concepto no cabe en el ancho disponible, **envuelve**. Esa es la
/// única variable que se mueve: la altura del renglón.
///
/// ## Por qué ya no se encoge por renglón
///
/// Hasta el 2026-08-28 este widget se llamaba `ConceptoEscalonado` y hacía otra
/// cosa: medía el texto con `TextPainter` y bajaba por una rampa
/// (`bodyLarge` → `bodyMedium` → `bodySmall`) hasta encontrar el escalón más
/// grande en que cupiera **en una sola línea**.
///
/// Funcionaba mientras los conceptos venían abreviados ('COL SEC ENERO'). Al
/// pasar a mostrarlos enteros ('COLEGIATURA SECUNDARIA ENERO') casi todos
/// bajaban de escalón, y la lista quedaba con un renglón a 16 px, el siguiente
/// a 14 y el siguiente a 12 según lo largo que fuera cada concepto. Además
/// rompía la congruencia con el importe, que sí conservaba su tamaño.
///
/// Entre una lista de altura pareja con letras de tamaños distintos y una lista
/// de tipografía uniforme con renglones de altura distinta, **se eligió la
/// segunda**: el tamaño de la letra es lo que el ojo compara entre renglones,
/// la altura no.
///
/// Sin medición, sin `TextPainter` y sin `LayoutBuilder`: el `Text` de Flutter
/// ya sabe envolver solo, y esto se pinta una vez por renglón en cada relayout
/// de la lista.
class ConceptoPago extends StatelessWidget {
  const ConceptoPago({super.key, required this.texto, this.color});

  /// Concepto tal como se pinta, completo.
  final String texto;

  /// Color del texto; por omisión, el del tema para contenido sobre superficie.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      texto,
      // Sin `maxLines` ni `overflow`: el texto envuelve las líneas que haga
      // falta y no hay ninguna vía por la que pueda quedar cortado. Poner un
      // tope de dos líneas reintroduciría el recorte justo en el caso que este
      // widget existe para evitar.
      style: theme.textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }
}
