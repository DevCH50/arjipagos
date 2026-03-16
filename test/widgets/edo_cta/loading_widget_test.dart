/// Tests para el widget EdoCtaLoadingWidget.
///
/// Verifica que el widget de carga se renderiza correctamente
/// con el indicador de progreso y el mensaje.
library;

import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdoCtaLoadingWidget', () {
    /// Helper para crear el widget con MaterialApp
    Widget createWidget() {
      return const MaterialApp(
        home: Scaffold(
          body: EdoCtaLoadingWidget(),
        ),
      );
    }

    testWidgets('muestra el CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica que existe el indicador de progreso
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra el mensaje de carga', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica el mensaje
      expect(find.text('Cargando estados de cuenta...'), findsOneWidget);
    });

    testWidgets('está centrado en la pantalla', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica que el indicador de progreso tiene un Center como ancestro
      final progress = find.byType(CircularProgressIndicator);
      expect(find.ancestor(of: progress, matching: find.byType(Center)), findsWidgets);
    });

    testWidgets('tiene la estructura correcta (Column)', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verifica que existe una Column
      expect(find.byType(Column), findsOneWidget);
    });
  });
}
