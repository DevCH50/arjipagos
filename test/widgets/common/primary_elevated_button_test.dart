/// Tests de widgets para PrimaryElevatedButton.
///
/// Este archivo contiene tests para verificar el comportamiento correcto
/// del widget PrimaryElevatedButton, incluyendo renderizado, callbacks
/// y estilos personalizados.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arjipagos/src/presentation/widgets/PrimaryElevatedButton.dart';

void main() {
  group('PrimaryElevatedButton', () {
    /// Test 1: Verifica que el widget renderiza correctamente con el texto dado.
    testWidgets('renderiza correctamente con el texto dado',
        (WidgetTester tester) async {
      // Arrange
      const textoEsperado = 'Mi Botón';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: textoEsperado,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      // Verifica que el texto se muestra en el widget
      expect(find.text(textoEsperado), findsOneWidget);

      // Verifica que es un ElevatedButton
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    /// Test 2: Verifica que ejecuta onPressed cuando se presiona el botón.
    testWidgets('ejecuta onPressed cuando se presiona',
        (WidgetTester tester) async {
      // Arrange
      bool fuePresionado = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: 'Presionar',
              onPressed: () {
                fuePresionado = true;
              },
            ),
          ),
        ),
      );

      // Simula un tap en el botón
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(fuePresionado, isTrue);
    });

    /// Test 3: Verifica que usa el color primario del tema cuando no se especifica.
    testWidgets('usa el color por defecto cuando no se especifica',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: 'Botón Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert — El color de fondo debe ser el primary del tema por defecto
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final estilo = boton.style;
      final colorFondo = estilo?.backgroundColor?.resolve({});

      // Sin color personalizado se usa colorScheme.primary del tema activo
      expect(colorFondo, equals(ThemeData().colorScheme.primary));
    });

    /// Test 4: Verifica que usa el color personalizado cuando se especifica.
    testWidgets('usa el color personalizado cuando se especifica',
        (WidgetTester tester) async {
      // Arrange
      const colorPersonalizado = Colors.red;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: 'Botón Personalizado',
              onPressed: () {},
              color: colorPersonalizado,
            ),
          ),
        ),
      );

      // Assert
      // Busca el ElevatedButton y verifica su estilo
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final estilo = boton.style;

      // Obtiene el color de fondo del botón
      final colorFondo = estilo?.backgroundColor?.resolve({});

      expect(colorFondo, equals(colorPersonalizado));
    });

    /// Test adicional: Verifica que el botón tiene el padding correcto.
    testWidgets('tiene el padding y border radius correcto',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: 'Botón',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final estilo = boton.style;

      // Verifica el padding
      final padding = estilo?.padding?.resolve({}) as EdgeInsets?;
      expect(padding?.horizontal, equals(80)); // 40 * 2
      expect(padding?.vertical, equals(30)); // 15 * 2

      // Verifica el shape (border radius)
      final shape = estilo?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, equals(BorderRadius.circular(25)));
    });

    /// Test adicional: Verifica que el texto tiene el estilo correcto.
    /// Sin color personalizado, usa onPrimary del tema (blanco por defecto).
    testWidgets('el texto tiene el estilo correcto',
        (WidgetTester tester) async {
      // Arrange
      const textoBoton = 'Texto Estilizado';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryElevatedButton(
              text: textoBoton,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert — fontSize siempre 18; color = onPrimary del tema (blanco)
      final texto = tester.widget<Text>(find.text(textoBoton));
      expect(texto.style?.fontSize, equals(18));
      expect(texto.style?.color, equals(ThemeData().colorScheme.onPrimary));
    });
  });
}
