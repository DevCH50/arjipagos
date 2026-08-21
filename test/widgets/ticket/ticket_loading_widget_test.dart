/// Tests para TicketLoadingWidget.
///
/// Cubre las dos esperas del flujo: por defecto anuncia la descarga del PDF y,
/// con mensaje propio, la apertura del documento en el visor.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketLoadingWidget', () {
    /// Helper para crear el widget con el tema indicado.
    Widget crearWidget({String? mensaje, ThemeData? tema}) {
      return MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(
          body: mensaje == null
              ? const TicketLoadingWidget()
              : TicketLoadingWidget(mensaje: mensaje),
        ),
      );
    }

    testWidgets('por defecto anuncia la descarga', (tester) async {
      await tester.pumpWidget(crearWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.ticketDescargando), findsOneWidget);
    });

    testWidgets('acepta el mensaje del visor', (tester) async {
      await tester.pumpWidget(
        crearWidget(mensaje: AppStrings.ticketPreparando),
      );

      expect(find.text(AppStrings.ticketPreparando), findsOneWidget);
      expect(find.text(AppStrings.ticketDescargando), findsNothing);
    });

    testWidgets('se pinta en tema oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.dark));

      expect(tester.takeException(), isNull);
    });
  });
}
