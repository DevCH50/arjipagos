/// Tests de widgets para GlassContainer.
///
/// Este archivo contiene pruebas para verificar el comportamiento
/// del widget GlassContainer, incluyendo:
/// - Renderizado correcto del child
/// - Aplicación de dimensiones según factores
/// - Aplicación del borderRadius
/// - Comportamiento de scroll
/// - Respeto de maxWidth y maxHeight
library;

import 'package:arjipagos/src/presentation/widgets/GlassContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlassContainer', () {
    // =========================================================================
    // Test 1: Renderiza el child correctamente
    // =========================================================================
    testWidgets('renderiza el child correctamente', (WidgetTester tester) async {
      // Arrange: Crear un widget hijo identificable
      const childWidget = Text('Contenido de prueba');

      // Act: Construir el GlassContainer con el child
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                child: childWidget,
              ),
            ),
          ),
        ),
      );

      // Assert: Verificar que el child se renderiza
      expect(find.text('Contenido de prueba'), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
    });

    // =========================================================================
    // Test 2: Aplica dimensiones correctas según factores
    // =========================================================================
    testWidgets('aplica dimensiones correctas según widthFactor y heightFactor',
        (WidgetTester tester) async {
      // Arrange: Definir factores de dimensión
      const widthFactor = 0.5;
      const heightFactor = 0.4;

      // Tamaño de pantalla de prueba (800x600)
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Act: Construir el widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                widthFactor: widthFactor,
                heightFactor: heightFactor,
                maxWidth: 1000, // Mayor que el calculado para no limitar
                maxHeight: 1000, // Mayor que el calculado para no limitar
                child: Text('Test'),
              ),
            ),
          ),
        ),
      );

      // Assert: Verificar que el tamaño renderizado es correcto
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(GlassContainer),
      );
      // El ancho debe ser 800 * 0.5 = 400, clamp(0, 1000) = 400
      expect(renderBox.size.width, equals(400.0));
      // El alto debe ser 600 * 0.4 = 240, clamp(0, 1000) = 240
      expect(renderBox.size.height, equals(240.0));

      // Limpiar tamaño de superficie
      await tester.binding.setSurfaceSize(null);
    });

    // =========================================================================
    // Test 3: Aplica el borderRadius correcto
    // =========================================================================
    testWidgets('aplica el borderRadius correcto', (WidgetTester tester) async {
      // Arrange: Definir un borderRadius personalizado
      const customBorderRadius = 25.0;

      // Act: Construir el widget con borderRadius personalizado
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                borderRadius: customBorderRadius,
                child: Text('Test'),
              ),
            ),
          ),
        ),
      );

      // Assert: Encontrar el Container y verificar su decoración
      final containerFinder = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;

      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(customBorderRadius)),
      );
    });

    // =========================================================================
    // Test 4: Es scrollable cuando scrollable=true
    // =========================================================================
    testWidgets('es scrollable cuando scrollable=true',
        (WidgetTester tester) async {
      // Arrange & Act: Construir con scrollable=true (valor por defecto)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                scrollable: true,
                child: Text('Contenido scrollable'),
              ),
            ),
          ),
        ),
      );

      // Assert: Debe existir un SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // =========================================================================
    // Test 5: No es scrollable cuando scrollable=false
    // =========================================================================
    testWidgets('no es scrollable cuando scrollable=false',
        (WidgetTester tester) async {
      // Arrange & Act: Construir con scrollable=false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                scrollable: false,
                child: Text('Contenido no scrollable'),
              ),
            ),
          ),
        ),
      );

      // Assert: No debe existir SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsNothing);
      // Pero el child sí debe renderizarse
      expect(find.text('Contenido no scrollable'), findsOneWidget);
    });

    // =========================================================================
    // Test 6: Respeta maxWidth y maxHeight
    // =========================================================================
    testWidgets('respeta maxWidth y maxHeight en pantallas grandes',
        (WidgetTester tester) async {
      // Arrange: Definir maxWidth y maxHeight pequeños
      const maxWidth = 300.0;
      const maxHeight = 200.0;

      // Simular pantalla grande (1200x900)
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      // Act: Construir el widget con factores grandes
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                widthFactor: 0.9, // 1200 * 0.9 = 1080, pero max es 300
                heightFactor: 0.9, // 900 * 0.9 = 810, pero max es 200
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                child: Text('Test'),
              ),
            ),
          ),
        ),
      );

      // Assert: Verificar que se respetan los límites máximos
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(GlassContainer),
      );

      // El ancho no debe exceder maxWidth
      expect(renderBox.size.width, equals(maxWidth));
      // El alto no debe exceder maxHeight
      expect(renderBox.size.height, equals(maxHeight));

      // Limpiar tamaño de superficie
      await tester.binding.setSurfaceSize(null);
    });

    // =========================================================================
    // Tests adicionales para mayor cobertura
    // =========================================================================
    group('valores por defecto', () {
      testWidgets('aplica backgroundColor por defecto',
          (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContainer(
                  child: Text('Test'),
                ),
              ),
            ),
          ),
        );

        // Assert: Verificar color por defecto (blanco con 25% opacidad)
        final containerFinder = find.byType(Container).first;
        final containerWidget = tester.widget<Container>(containerFinder);
        final decoration = containerWidget.decoration as BoxDecoration;

        expect(
          decoration.color,
          equals(const Color.fromRGBO(255, 255, 255, 0.25)),
        );
      });

      testWidgets('aplica padding por defecto', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContainer(
                  child: Text('Test'),
                ),
              ),
            ),
          ),
        );

        // Assert: Verificar padding por defecto (EdgeInsets.all(20))
        final containerFinder = find.byType(Container).first;
        final containerWidget = tester.widget<Container>(containerFinder);

        expect(containerWidget.padding, equals(const EdgeInsets.all(20)));
      });
    });

    group('heightFactor null', () {
      testWidgets('cuando heightFactor es null, el alto se ajusta al contenido',
          (WidgetTester tester) async {
        // Act: Construir con heightFactor = null
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContainer(
                  heightFactor: null,
                  child: SizedBox(
                    height: 100,
                    child: Text('Contenido con alto fijo'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Assert: El widget debe renderizarse sin problemas
        expect(find.byType(GlassContainer), findsOneWidget);
        expect(find.text('Contenido con alto fijo'), findsOneWidget);
      });
    });

    group('personalización de estilos', () {
      testWidgets('aplica backgroundColor personalizado',
          (WidgetTester tester) async {
        // Arrange
        const customColor = Color.fromRGBO(0, 0, 0, 0.5);

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContainer(
                  backgroundColor: customColor,
                  child: Text('Test'),
                ),
              ),
            ),
          ),
        );

        // Assert
        final containerFinder = find.byType(Container).first;
        final containerWidget = tester.widget<Container>(containerFinder);
        final decoration = containerWidget.decoration as BoxDecoration;

        expect(decoration.color, equals(customColor));
      });

      testWidgets('aplica padding personalizado', (WidgetTester tester) async {
        // Arrange
        const customPadding = EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 15,
        );

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContainer(
                  padding: customPadding,
                  child: Text('Test'),
                ),
              ),
            ),
          ),
        );

        // Assert
        final containerFinder = find.byType(Container).first;
        final containerWidget = tester.widget<Container>(containerFinder);

        expect(containerWidget.padding, equals(customPadding));
      });
    });
  });
}
