/// Tests para TicketAccionesBar.
///
/// La barra vive bajo el visor del ticket. Verifica que ofrece las dos salidas
/// (compartir y abrir en otra app), que cada una avisa a su callback y que se
/// pinta en tema claro y oscuro.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/ticket_acciones_bar.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketAccionesBar', () {
    int compartidos = 0;
    int aperturas = 0;

    setUp(() {
      compartidos = 0;
      aperturas = 0;
    });

    /// Helper para crear el widget con el tema indicado.
    Widget crearWidget({required ThemeData tema}) {
      return MaterialApp(
        theme: tema,
        home: Scaffold(
          body: TicketAccionesBar(
            onCompartir: () => compartidos++,
            onAbrirFuera: () => aperturas++,
          ),
        ),
      );
    }

    testWidgets('muestra las dos acciones', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.light));

      expect(find.text(AppStrings.ticketCompartir), findsOneWidget);
      expect(find.text(AppStrings.ticketAbrirEnOtraApp), findsOneWidget);
    });

    testWidgets('compartir avisa a su callback', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.light));

      await tester.tap(find.text(AppStrings.ticketCompartir));
      await tester.pump();

      expect(compartidos, 1);
      expect(aperturas, 0);
    });

    testWidgets('abrir en otra app avisa a su callback', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.light));

      await tester.tap(find.text(AppStrings.ticketAbrirEnOtraApp));
      await tester.pump();

      expect(aperturas, 1);
      expect(compartidos, 0);
    });

    testWidgets('se pinta en tema oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(crearWidget(tema: AppTheme.dark));

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.ticketCompartir), findsOneWidget);
    });

    testWidgets('no desborda en una pantalla angosta ni con la fuente al doble',
        (tester) async {
      // 360 dp de ancho es el caso real donde la versión en fila desbordaba
      // por 2 px; con la fuente del sistema al doble el margen desaparece.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: TicketAccionesBar(
                  onCompartir: () => compartidos++,
                  onAbrirFuera: () => aperturas++,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
