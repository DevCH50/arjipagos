/// Tests de widget para [UserDrawerHeader].
///
/// Fijan el contrato del header del drawer después de simplificarlo:
/// - Muestra SOLO el nombre de pila, junto al avatar y a su derecha.
/// - NO muestra correo ni apellidos. Es lo que se pidió quitar, así que un test
///   lo protege de volver a colarse en una refactorización.
/// - El avatar lleva la inicial del nombre, con respaldo cuando llega vacío.
library;

import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/drawer_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Monta el header aislado con el ancho de drawer indicado.
  Future<void> montar(WidgetTester tester, String nombre,
      {double ancho = 304}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: ancho, // 304 es el ancho por defecto de un Drawer Material
            child: UserDrawerHeader(nombre: nombre),
          ),
        ),
      ),
    );
  }

  group('UserDrawerHeader', () {
    testWidgets('muestra el nombre recibido', (tester) async {
      await montar(tester, 'Ileana Kristell');

      expect(find.text('Ileana Kristell'), findsOneWidget);
    });

    testWidgets('pinta la inicial del nombre en el avatar', (tester) async {
      await montar(tester, 'Ileana');

      expect(find.text('I'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('cae a la inicial de respaldo con el nombre vacío',
        (tester) async {
      // Sin este respaldo, `nombre[0]` reventaría con un String vacío.
      await montar(tester, '');

      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('no muestra ningún correo', (tester) async {
      // El header ya no acepta email; el test protege que no vuelva a aparecer.
      await montar(tester, 'Ileana Kristell');

      final textos = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();

      expect(textos.any((t) => t.contains('@')), isFalse);
    });

    testWidgets('coloca el nombre a la derecha del avatar', (tester) async {
      await montar(tester, 'Ileana');

      final avatar = tester.getRect(find.byType(CircleAvatar));
      final nombre = tester.getRect(find.text('Ileana'));

      // A la derecha, no debajo: empieza después del avatar y comparten franja
      // vertical.
      expect(nombre.left, greaterThan(avatar.right));
      expect(nombre.center.dy, closeTo(avatar.center.dy, 2));
    });

    testWidgets('recorta un nombre largo en vez de desbordar', (tester) async {
      await montar(tester, 'Maximiliano Cuauhtémoc Bernabé de la Concepción');

      // Sin overflow no hay excepción de layout; además el Text debe estar
      // limitado, que es lo que evita que empuje al avatar fuera de la fila.
      final texto = tester.widget<Text>(
        find.text('Maximiliano Cuauhtémoc Bernabé de la Concepción'),
      );

      expect(texto.maxLines, 2);
      expect(texto.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aguanta un drawer estrecho sin desbordar', (tester) async {
      // En pantallas pequeñas el drawer se queda por debajo de los 304 dp.
      // El avatar es de ancho fijo, así que el que tiene que ceder es el texto.
      await montar(tester, 'Ileana Kristell', ancho: 220);

      expect(tester.takeException(), isNull);
      expect(find.text('Ileana Kristell'), findsOneWidget);
    });
  });
}
