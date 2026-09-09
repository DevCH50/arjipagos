import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/adorno_estacional.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/franja_estacional.dart';
import 'package:flutter/material.dart';

/// El listón de la temporada: una franja de color y, debajo, el motivo.
///
/// Va justo bajo la cabecera del Menú Principal, **ocupando el hueco del
/// `Divider` que ya había ahí**. Esa elección no es casual: fuera de temporada
/// este widget devuelve exactamente ese mismo `Divider`, así que apagar la
/// decoración —o que llegue octubre— no mueve ni un píxel del resto de la
/// pantalla. No hay que quitar nada ni recolocar el layout.
///
/// La franja va **debajo** de la banda dorada y no encima ni en lugar de ella:
/// el dorado es el color de la marca y sigue mandando doce meses al año. La
/// decoración acompaña, no sustituye.
class ListonEstacional extends StatelessWidget {
  const ListonEstacional({super.key});

  /// Alto de la franja de color. Tres píxeles: se ve, y no se lee como si
  /// fuera un elemento con el que se pueda interactuar.
  static const double _altoFranja = 3;

  /// Alto del motivo. Quince píxeles es lo justo para que el papel picado se
  /// reconozca como papel picado y no como una tira de dientes de sierra.
  static const double _altoMotivo = 15;

  @override
  Widget build(BuildContext context) {
    final DecoracionEstacional? decoracion =
        Theme.of(context).extension<DecoracionEstacional>();

    if (decoracion == null || !decoracion.hayDecoracion) {
      // Lo que había antes de todo esto, tal cual.
      return const Divider(height: 1);
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FranjaEstacional(alto: _altoFranja),
        AdornoEstacional(alto: _altoMotivo),
      ],
    );
  }
}
