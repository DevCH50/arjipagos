/// Tests para el widget CarritoEmptyWidget.
///
/// Verifica que el widget de carrito vacío se renderiza correctamente
/// con todos sus elementos visuales y funcionalidad.
library;

import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarritoEmptyWidget', () {
    /// Helper para crear el widget con MaterialApp
    Widget createWidget() {
      return const MaterialApp(
        home: Scaffold(
          body: CarritoEmptyWidget(),
        ),
      );
    }

    testWidgets('muestra el ícono de carrito vacío', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica que existe el ícono de carrito
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('muestra el título "Carrito vacío"', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica el título
      expect(find.text('Carrito vacío'), findsOneWidget);
    });

    testWidgets('muestra el mensaje de instrucción', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica el mensaje
      expect(
        find.text('Selecciona pagos desde Estados de Cuenta'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el botón "Volver"', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica el botón
      expect(find.text('Volver'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('el botón Volver hace pop de la navegación', (tester) async {
      var didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PopScope(
                        canPop: true,
                        onPopInvokedWithResult: (didPopResult, result) {
                          didPop = true;
                        },
                        child: const Scaffold(
                          body: CarritoEmptyWidget(),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Ir'),
              ),
            ),
          ),
        ),
      );

      // Navega a la pantalla con CarritoEmptyWidget
      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();

      // Presiona el botón Volver
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      // Verifica que se hizo pop
      expect(didPop, isTrue);
    });

    testWidgets('está centrado en la pantalla', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica que CarritoEmptyWidget tiene un Center como ancestro
      final carritoEmpty = find.byType(CarritoEmptyWidget);
      expect(carritoEmpty, findsOneWidget);

      // Verifica que el ícono del carrito está centrado
      final icon = find.byIcon(Icons.shopping_cart_outlined);
      expect(find.ancestor(of: icon, matching: find.byType(Center)), findsWidgets);
    });

    testWidgets('el ícono tiene el tamaño correcto (80)', (tester) async {
      await tester.pumpWidget(createWidget());

      // Busca el ícono y verifica su tamaño
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.shopping_cart_outlined),
      );
      expect(icon.size, equals(80));
    });
  });
}
