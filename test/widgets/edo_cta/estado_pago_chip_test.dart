// Tests para el widget EstadoPagoChip
// Este widget muestra el estado de pago (Pendiente/Vencido) con estilos visuales
// apropiados para cada estado y tema (claro/oscuro)

import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta la píldora suelta, con el tema y el contexto de tinte que pida el test.
Future<void> montar(
  WidgetTester tester,
  EstadoPago estado, {
  ThemeData? tema,
  bool sobreTinte = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: tema,
      home: Scaffold(
        body: EstadoPagoChip(estadoPago: estado, sobreTinte: sobreTinte),
      ),
    ),
  );
}

/// `Container` de la píldora: el ancestro más cercano de su texto.
///
/// Se busca así y no con `find.byType(Container)` porque el punto de color es
/// también un `Container`, y una búsqueda por tipo devolvería los dos.
Container pildora(WidgetTester tester, String etiqueta) {
  return tester.widget<Container>(
    find
        .ancestor(of: find.text(etiqueta), matching: find.byType(Container))
        .first,
  );
}

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

    // Los colores salen del `ColorScheme` del tema, no de constantes: es lo
    // que hace que claro y oscuro se resuelvan solos. Por eso los tests leen
    // el esquema en vez de comparar contra hexes escritos a mano.
    for (final tema in <({String nombre, ThemeData datos})>[
      (nombre: 'tema claro', datos: ThemeData.light()),
      (nombre: 'tema oscuro', datos: ThemeData.dark()),
    ]) {
      group(tema.nombre, () {
        testWidgets('la píldora usa el contenedor del tema y radio 8',
            (WidgetTester tester) async {
          await montar(tester, EstadoPago.pendiente, tema: tema.datos);

          final decoracion = pildora(tester, 'Pendiente').decoration!;

          expect((decoracion as BoxDecoration).borderRadius,
              BorderRadius.circular(8));
          expect(decoracion.color, tema.datos.colorScheme.surfaceContainerHighest);
        });

        testWidgets('sobre un renglón teñido la píldora se despega con surface',
            (WidgetTester tester) async {
          await montar(tester, EstadoPago.vencido,
              tema: tema.datos, sobreTinte: true);

          final decoracion =
              pildora(tester, 'Vencido').decoration! as BoxDecoration;

          expect(decoracion.color, tema.datos.colorScheme.surface);
        });

        testWidgets('el pendiente se escribe en el gris de apoyo',
            (WidgetTester tester) async {
          await montar(tester, EstadoPago.pendiente, tema: tema.datos);

          final texto = tester.widget<Text>(find.text('Pendiente'));

          expect(texto.style?.fontSize, 11);
          expect(texto.style?.fontWeight, FontWeight.w500);
          expect(texto.style?.letterSpacing, 0.5);
          expect(texto.style?.color, tema.datos.colorScheme.onSurfaceVariant);
        });

        testWidgets('el vencido se escribe en el color de error del tema',
            (WidgetTester tester) async {
          await montar(tester, EstadoPago.vencido, tema: tema.datos);

          final texto = tester.widget<Text>(find.text('Vencido'));

          expect(texto.style?.color, tema.datos.colorScheme.error);
        });
      });
    }

    // =========================================================================
    // TESTS DE ESTRUCTURA
    // =========================================================================

    testWidgets('tiene el padding correcto', (WidgetTester tester) async {
      await montar(tester, EstadoPago.pendiente);

      expect(
        pildora(tester, 'Pendiente').padding,
        const EdgeInsets.fromLTRB(8, 3, 10, 3),
      );
    });

    testWidgets('lleva un punto de color además del texto',
        (WidgetTester tester) async {
      // El punto es refuerzo, no sustituto: el estado se sigue leyendo escrito
      // para quien no percibe el color.
      await montar(tester, EstadoPago.pendiente);

      final punto = tester.widget<Container>(find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle));

      expect((punto.decoration! as BoxDecoration).color, AppColors.warning);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('el punto del vencido sale del color de error del tema',
        (WidgetTester tester) async {
      final tema = ThemeData.light();
      await montar(tester, EstadoPago.vencido, tema: tema);

      final punto = tester.widget<Container>(find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle));

      expect((punto.decoration! as BoxDecoration).color, tema.colorScheme.error);
    });
  });
}
