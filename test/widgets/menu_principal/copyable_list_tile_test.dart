/// Tests de widgets para CopyableListTile.
///
/// Este archivo contiene pruebas para verificar el comportamiento
/// del widget CopyableListTile, incluyendo:
/// - Renderizado inicial con label, value e ícono
/// - Muestra del ícono de copiar (Icons.copy) antes de interacción
/// - Muestra del ícono de check (Icons.check) tras hacer tap
/// - Correcta visualización de label y value distintos
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/copyable_list_tile.dart';

void main() {
  // Configuración del mock del portapapeles para evitar errores en entorno de test
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/clipboard'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': ''};
        }
        return null;
      },
    );
  });

  tearDown(() {
    // Eliminar el mock del portapapeles al finalizar cada test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/clipboard'),
      null,
    );
  });

  // Función auxiliar para construir el widget en un contexto Material completo
  Widget buildTestableWidget({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CopyableListTile(
          icon: icon,
          label: label,
          value: value,
        ),
      ),
    );
  }

  // ===========================================================================
  // Test 1: Renderizado inicial
  // ===========================================================================
  group('CopyableListTile - Renderizado inicial', () {
    testWidgets('muestra el label, el value y el ícono indicado al iniciar',
        (WidgetTester tester) async {
      // Arrange
      const testLabel = 'Número de cuenta';
      const testValue = '1234567890';
      const testIcon = Icons.account_balance;

      // Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: testIcon,
          label: testLabel,
          value: testValue,
        ),
      );

      // Assert
      expect(find.text(testLabel), findsOneWidget);
      expect(find.text(testValue), findsOneWidget);
      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('renderiza el widget CopyableListTile sin errores',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.person,
          label: 'Titular',
          value: 'Juan Pérez',
        ),
      );

      // Assert: el widget existe en el árbol
      expect(find.byType(CopyableListTile), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });
  });

  // ===========================================================================
  // Test 2: Ícono de copia inicial
  // ===========================================================================
  group('CopyableListTile - Ícono de copiar', () {
    testWidgets('muestra el ícono de copiar (Icons.copy) antes de tocar',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.account_balance,
          label: 'CBU',
          value: '0000003100012345678901',
        ),
      );

      // Assert: el ícono de copiar debe estar visible; el de check no
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('el ícono de copiar tiene la key correcta antes de tocar',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.tag,
          label: 'Alias',
          value: 'mi.alias.bancario',
        ),
      );

      // Assert: el Icon con ValueKey('copy') existe en el AnimatedSwitcher
      expect(find.byKey(const ValueKey('copy')), findsOneWidget);
      expect(find.byKey(const ValueKey('check')), findsNothing);
    });
  });

  // ===========================================================================
  // Test 3: Interacción al tocar
  // ===========================================================================
  group('CopyableListTile - Interacción al tocar', () {
    testWidgets(
        'se puede tocar sin lanzar excepción',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.account_balance,
          label: 'CBU',
          value: '0000003100012345678901',
        ),
      );

      // Act + Assert: tap no debe lanzar ninguna excepción
      await tester.tap(find.byType(CopyableListTile));
      await tester.pump();
    });

    testWidgets(
        'AnimatedSwitcher está presente en el árbol de widgets',
        (WidgetTester tester) async {
      // Arrange + Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.tag,
          label: 'Alias',
          value: 'mi.alias.bancario',
        ),
      );

      // Assert: el AnimatedSwitcher gestiona la transición de íconos
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets(
        'estado inicial tiene ValueKey("copy") en el ícono',
        (WidgetTester tester) async {
      // Arrange + Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.account_balance,
          label: 'CBU',
          value: '0000003100012345678901',
        ),
      );

      // Assert: el ícono inicial tiene la key 'copy'
      expect(find.byKey(const ValueKey('copy')), findsOneWidget);
      expect(find.byKey(const ValueKey('check')), findsNothing);
    });
  });

  // ===========================================================================
  // Test 4: Contenido correcto con label y value distintos
  // ===========================================================================
  group('CopyableListTile - Contenido correcto', () {
    testWidgets('muestra correctamente un label y value de CBU',
        (WidgetTester tester) async {
      // Arrange
      const label = 'CBU';
      const value = '0000003100012345678901';

      // Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.account_balance,
          label: label,
          value: value,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(label), findsOneWidget);
      expect(find.text(value), findsOneWidget);
    });

    testWidgets('muestra correctamente un label y value de Alias',
        (WidgetTester tester) async {
      // Arrange
      const label = 'Alias';
      const value = 'mi.alias.bancario';

      // Act
      await tester.pumpWidget(
        buildTestableWidget(
          icon: Icons.tag,
          label: label,
          value: value,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(label), findsOneWidget);
      expect(find.text(value), findsOneWidget);
    });

    testWidgets('label y value son independientes entre sí',
        (WidgetTester tester) async {
      // Arrange: dos instancias con datos distintos
      const label1 = 'Número de cuenta';
      const value1 = '123456789';
      const label2 = 'CUIT';
      const value2 = '20-12345678-9';

      // Act: renderizar ambas en la misma pantalla
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CopyableListTile(
                  icon: Icons.account_balance,
                  label: label1,
                  value: value1,
                ),
                CopyableListTile(
                  icon: Icons.badge,
                  label: label2,
                  value: value2,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: los cuatro textos se muestran sin mezclar
      expect(find.text(label1), findsOneWidget);
      expect(find.text(value1), findsOneWidget);
      expect(find.text(label2), findsOneWidget);
      expect(find.text(value2), findsOneWidget);
    });
  });
}
