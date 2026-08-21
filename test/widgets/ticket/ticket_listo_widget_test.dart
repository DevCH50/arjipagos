/// Tests para TicketListoWidget.
///
/// Es el panel de respaldo cuando el PDF está descargado pero el visor de la
/// app no lo pudo pintar: debe confirmar que el archivo está listo, mostrar el
/// folio cuando existe y explicar por qué no se ve el documento.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_listo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketListoWidget', () {
    /// Helper para crear el widget con el tema indicado.
    Widget crearWidget({String folio = 'T7719', ThemeData? tema}) {
      return MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(
          body: TicketListoWidget(
            folio: folio,
            explicacion: AppStrings.ticketErrorVisor,
          ),
        ),
      );
    }

    testWidgets('confirma que el ticket está listo y explica el motivo',
        (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(find.text(AppStrings.ticketListo), findsOneWidget);
      expect(find.text(AppStrings.ticketErrorVisor), findsOneWidget);
    });

    testWidgets('muestra el folio cuando el backend lo envía', (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(
        find.text('${AppStrings.edoCtaPagadosFolio} T7719'),
        findsOneWidget,
      );
    });

    testWidgets('omite la línea del folio si llega vacío', (tester) async {
      await tester.pumpWidget(crearWidget(folio: ''));

      expect(
        find.textContaining(AppStrings.edoCtaPagadosFolio),
        findsNothing,
      );
    });

    testWidgets('no ofrece botones: las acciones viven en la barra',
        (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('se pinta en tema oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.dark));

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.ticketListo), findsOneWidget);
    });
  });
}
