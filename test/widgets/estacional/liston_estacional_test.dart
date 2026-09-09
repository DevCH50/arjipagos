/// Los widgets de la decoración estacional.
///
/// **La temporada se inyecta por el tema, no por el reloj.** Cada montaje
/// reemplaza la extensión con `copyWith(extensions: [...])`, así que estos tests
/// prueban septiembre en abril sin mockear `DateTime.now()` y sin depender del
/// mes en que se ejecuten. Ésa fue la razón principal para montar la decoración
/// como `ThemeExtension`.
///
/// Se comprueba **claro y oscuro** siguiendo el patrón de
/// `test/widgets/edo_cta/pago_item_test.dart`: el helper de montaje recibe el
/// `Brightness` y arma el `AppTheme` que toca.
library;

import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:arjipagos/src/core/theme/estacional/temporada.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/adorno_estacional.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/franja_estacional.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/liston_estacional.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Monta [widget] con la decoración de [temporada] y el brillo pedido.
  Future<void> montar(
    WidgetTester tester,
    Widget widget, {
    required Temporada temporada,
    Brightness brillo = Brightness.light,
  }) async {
    final ThemeData base =
        brillo == Brightness.dark ? AppTheme.dark : AppTheme.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(
          extensions: <ThemeExtension<dynamic>>[
            DecoracionEstacional.de(temporada, brillo: brillo),
          ],
        ),
        home: Scaffold(body: widget),
      ),
    );
  }

  group('ListonEstacional', () {
    testWidgets('fuera de temporada devuelve el Divider de siempre', (
      tester,
    ) async {
      await montar(
        tester,
        const ListonEstacional(),
        temporada: Temporada.ninguna,
      );

      // Es la garantía de que octubre se ve exactamente igual que antes de
      // existir la decoración: el hueco lo sigue ocupando un `Divider`.
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(FranjaEstacional), findsNothing);
      expect(find.byType(AdornoEstacional), findsNothing);
    });

    testWidgets('en temporada pinta la franja y el motivo', (tester) async {
      await montar(
        tester,
        const ListonEstacional(),
        temporada: Temporada.patria,
      );

      expect(find.byType(Divider), findsNothing);
      expect(find.byType(FranjaEstacional), findsOneWidget);
      expect(find.byType(AdornoEstacional), findsOneWidget);
    });

    testWidgets('en tema oscuro también', (tester) async {
      await montar(
        tester,
        const ListonEstacional(),
        temporada: Temporada.patria,
        brillo: Brightness.dark,
      );

      expect(find.byType(FranjaEstacional), findsOneWidget);
      expect(find.byType(AdornoEstacional), findsOneWidget);
    });

    testWidgets('las paletas clara y oscura son distintas', (tester) async {
      // No es un capricho: el verde bandera y el morado de altar se pierden
      // sobre fondo oscuro. Si alguien unifica las paletas «para simplificar»,
      // este test lo cuenta.
      final DecoracionEstacional claro =
          DecoracionEstacional.de(Temporada.patria);
      final DecoracionEstacional oscuro = DecoracionEstacional.de(
        Temporada.patria,
        brillo: Brightness.dark,
      );

      expect(claro.colores, isNot(equals(oscuro.colores)));
    });
  });

  group('AdornoEstacional', () {
    testWidgets('fuera de temporada no ocupa nada', (tester) async {
      await montar(
        tester,
        const AdornoEstacional(),
        temporada: Temporada.ninguna,
      );

      // Se busca el `CustomPaint` **dentro del adorno**, no en toda la
      // pantalla: `Divider`, `Material` y `Scaffold` traen los suyos, y un
      // `findsNothing` a secas fallaría por culpa de ellos.
      expect(
        find.descendant(
          of: find.byType(AdornoEstacional),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(AdornoEstacional)), Size.zero);
    });

    testWidgets('se anuncia como adorno para el lector de pantalla', (
      tester,
    ) async {
      await montar(
        tester,
        const AdornoEstacional(),
        temporada: Temporada.muertos,
      );

      // La etiqueta dice que es un adorno, para que quien navegue con TalkBack
      // no crea que se está perdiendo información.
      expect(find.bySemanticsLabel('Adorno del día de muertos'),
          findsOneWidget);
    });

    testWidgets('las siete temporadas se pintan sin reventar', (tester) async {
      // Cada temporada dibuja un motivo distinto, y todos son código nuevo de
      // `CustomPainter`. Recorrerlas es la forma barata de que un fallo de
      // geometría —un radio negativo, una división por cero— salte aquí y no en
      // el teléfono de un padre en mitad de un pago.
      for (final Temporada temporada in Temporada.values) {
        for (final Brightness brillo in Brightness.values) {
          await montar(
            tester,
            const AdornoEstacional(alto: 20),
            temporada: temporada,
            brillo: brillo,
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'falló $temporada en $brillo',
          );
        }
      }
    });
  });

  group('FranjaEstacional', () {
    testWidgets('fuera de temporada no ocupa nada', (tester) async {
      await montar(
        tester,
        const FranjaEstacional(),
        temporada: Temporada.ninguna,
      );

      expect(tester.getSize(find.byType(FranjaEstacional)), Size.zero);
    });

    testWidgets('respeta el ancho fijo que le den', (tester) async {
      // Lo usa el rótulo de «Avisos», donde la franja va corta a propósito para
      // no competir con el título de la sección.
      await montar(
        tester,
        const FranjaEstacional(alto: 4, ancho: 46),
        temporada: Temporada.navidad,
      );

      expect(
        tester.getSize(find.byType(FranjaEstacional)),
        const Size(46, 4),
      );
    });
  });
}
