/// El orden de la paleta de navidad, que no es cosmético.
///
/// **El dorado va en medio.** Hasta el 2026-09-09 el orden era verde, rojo,
/// dorado, y el degradado de [FranjaEstacional] —que interpola de un color al
/// siguiente— pasaba por el punto medio de **verde y rojo, que son
/// complementarios**: un café sucio de lado a lado del listón. El vivo de
/// navidad parecía otoño mal impreso.
///
/// Con el dorado entre los dos, las dos transiciones son limpias: verde a
/// dorado pasa por oliva, y dorado a rojo por naranja.
///
/// Y el **verde tiene que seguir siendo el primero**: `MotivoEstacionalPainter`
/// pinta con él las dos capas del follaje de la guirnalda
/// (`colores.first`). Si alguien reordena la paleta y lo mueve, la guirnalda
/// sale roja o dorada sin que falle nada más.
///
/// Se comprueba por **tono** y no por valor exacto: así los colores se pueden
/// afinar —subirles saturación, adaptarlos a un tema nuevo— sin tocar el test,
/// que es lo que se quiere vigilar y lo que no.
library;

import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:arjipagos/src/core/theme/estacional/temporada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paleta de navidad', () {
    for (final Brightness brillo in Brightness.values) {
      test('el dorado va en medio, entre el verde y el rojo (${brillo.name})',
          () {
        final List<double> tonos = DecoracionEstacional.de(
          Temporada.navidad,
          brillo: brillo,
        ).colores.map((Color c) => HSLColor.fromColor(c).hue).toList();

        expect(tonos, hasLength(3));
        // Verde ≈ 120°, dorado ≈ 45°, rojo ≈ 0°. El de en medio tiene que
        // quedar estrictamente entre los otros dos: es lo que impide que dos
        // complementarios acaben pegados en el degradado.
        expect(
          tonos[1] < tonos[0] && tonos[1] > tonos[2],
          isTrue,
          reason: 'El color de en medio (${tonos[1].round()}°) no separa al '
              'verde (${tonos[0].round()}°) del rojo (${tonos[2].round()}°). '
              'Pegados, el degradado de la franja pasa por café.',
        );
      });

      test('el verde de la guirnalda es el primero (${brillo.name})', () {
        final double tono = HSLColor.fromColor(
          DecoracionEstacional.de(Temporada.navidad, brillo: brillo).colores.first,
        ).hue;

        expect(
          tono,
          inInclusiveRange(90, 150),
          reason: 'El primer color ya no es verde, y es con el que se pinta el '
              'follaje de la guirnalda en MotivoEstacionalPainter.',
        );
      });
    }
  });
}
