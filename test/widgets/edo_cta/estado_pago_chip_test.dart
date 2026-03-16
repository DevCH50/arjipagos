// Tests para el widget EstadoPagoChip
// Este widget muestra el estado de pago (Pendiente/Vencido) con estilos visuales
// apropiados para cada estado y tema (claro/oscuro)

import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstadoPagoChip', () {
    // =========================================================================
    // TESTS DE TEXTO
    // =========================================================================

    testWidgets('muestra "Pendiente" cuando estadoPago es pendiente',
        (WidgetTester tester) async {
      // Arrange: Crear el widget con estado pendiente
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EstadoPagoChip(estadoPago: EstadoPago.pendiente),
          ),
        ),
      );

      // Assert: Verificar que muestra el texto "Pendiente"
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Vencido'), findsNothing);
    });

    testWidgets('muestra "Vencido" cuando estadoPago es vencido',
        (WidgetTester tester) async {
      // Arrange: Crear el widget con estado vencido
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EstadoPagoChip(estadoPago: EstadoPago.vencido),
          ),
        ),
      );

      // Assert: Verificar que muestra el texto "Vencido"
      expect(find.text('Vencido'), findsOneWidget);
      expect(find.text('Pendiente'), findsNothing);
    });

    // =========================================================================
    // TESTS DE ESTILO EN TEMA CLARO
    // =========================================================================

    group('tema claro', () {
      testWidgets('tiene el estilo correcto para estado pendiente',
          (WidgetTester tester) async {
        // Arrange: Crear el widget en tema claro con estado pendiente
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: EstadoPagoChip(estadoPago: EstadoPago.pendiente),
            ),
          ),
        );

        // Act: Obtener el Container y Text del widget
        final container = tester.widget<Container>(find.byType(Container));
        final text = tester.widget<Text>(find.text('Pendiente'));

        // Assert: Verificar decoración del container
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12));

        // Verificar color de fondo (warning con alpha 0.15 para tema claro)
        final expectedBgColor = AppColors.warning.withValues(alpha: 0.15);
        expect(decoration.color, expectedBgColor);

        // Verificar estilo del texto
        expect(text.style?.fontSize, 11);
        expect(text.style?.fontWeight, FontWeight.w500);
        expect(text.style?.color, AppColors.warning);
      });

      testWidgets('tiene el estilo correcto para estado vencido',
          (WidgetTester tester) async {
        // Arrange: Crear el widget en tema claro con estado vencido
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: EstadoPagoChip(estadoPago: EstadoPago.vencido),
            ),
          ),
        );

        // Act: Obtener el Container y Text del widget
        final container = tester.widget<Container>(find.byType(Container));
        final text = tester.widget<Text>(find.text('Vencido'));

        // Assert: Verificar decoración del container
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12));

        // Verificar color de fondo (error con alpha 0.15 para tema claro)
        final expectedBgColor = AppColors.error.withValues(alpha: 0.15);
        expect(decoration.color, expectedBgColor);

        // Verificar estilo del texto
        expect(text.style?.fontSize, 11);
        expect(text.style?.fontWeight, FontWeight.w500);
        expect(text.style?.color, AppColors.error);
      });
    });

    // =========================================================================
    // TESTS DE ESTILO EN TEMA OSCURO
    // =========================================================================

    group('tema oscuro', () {
      testWidgets('tiene el estilo correcto para estado pendiente',
          (WidgetTester tester) async {
        // Arrange: Crear el widget en tema oscuro con estado pendiente
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: EstadoPagoChip(estadoPago: EstadoPago.pendiente),
            ),
          ),
        );

        // Act: Obtener el Container y Text del widget
        final container = tester.widget<Container>(find.byType(Container));
        final text = tester.widget<Text>(find.text('Pendiente'));

        // Assert: Verificar decoración del container
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12));

        // Verificar color de fondo (warning con alpha 0.3 para tema oscuro)
        final expectedBgColor = AppColors.warning.withValues(alpha: 0.3);
        expect(decoration.color, expectedBgColor);

        // Verificar estilo del texto (warningLight para tema oscuro)
        expect(text.style?.fontSize, 11);
        expect(text.style?.fontWeight, FontWeight.w500);
        expect(text.style?.color, AppColors.warningLight);
      });

      testWidgets('tiene el estilo correcto para estado vencido',
          (WidgetTester tester) async {
        // Arrange: Crear el widget en tema oscuro con estado vencido
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: EstadoPagoChip(estadoPago: EstadoPago.vencido),
            ),
          ),
        );

        // Act: Obtener el Container y Text del widget
        final container = tester.widget<Container>(find.byType(Container));
        final text = tester.widget<Text>(find.text('Vencido'));

        // Assert: Verificar decoración del container
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12));

        // Verificar color de fondo (error con alpha 0.3 para tema oscuro)
        final expectedBgColor = AppColors.error.withValues(alpha: 0.3);
        expect(decoration.color, expectedBgColor);

        // Verificar estilo del texto (errorLight para tema oscuro)
        expect(text.style?.fontSize, 11);
        expect(text.style?.fontWeight, FontWeight.w500);
        expect(text.style?.color, AppColors.errorLight);
      });
    });

    // =========================================================================
    // TESTS DE ESTRUCTURA
    // =========================================================================

    testWidgets('tiene el padding correcto', (WidgetTester tester) async {
      // Arrange: Crear el widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EstadoPagoChip(estadoPago: EstadoPago.pendiente),
          ),
        ),
      );

      // Act: Obtener el Container del widget
      final container = tester.widget<Container>(find.byType(Container));

      // Assert: Verificar padding
      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      );
    });
  });
}
