// Test de widget: ActualizacionRequeridaDialog
//
// Se blindan dos cosas:
//
// 1. El candado: cuando la actualización es obligatoria —o el backend está en
//    mantenimiento— el diálogo NO se puede cerrar, ni con el botón atrás de
//    Android ni con el gesto de retroceso de iOS. Si esto falla, la
//    actualización forzada deja de forzar nada.
// 2. Que **todo** cierre legítimo devuelva un [CierreActualizacion]. De eso
//    depende que `ActualizacionObserver` distinga a un usuario que descarta el
//    aviso de una navegación que se llevó la ruta por delante.

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/presentation/widgets/ActualizacionRequeridaDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const urlTienda = 'https://play.google.com/store/apps/details?id=x';

  /// Motivo con el que se cerró el diálogo en la última prueba.
  CierreActualizacion? cierre;

  setUp(() => cierre = null);

  /// Monta el diálogo como ruta, para poder probar el botón atrás de verdad.
  ///
  /// Se abre igual que lo hace `ActualizacionObserver`, con
  /// `barrierDismissible: false` siempre.
  Future<void> montar(
    WidgetTester tester,
    ResultadoActualizacion resultado, {
    ThemeMode tema = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: tema,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                cierre = await showDialog<CierreActualizacion>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      ActualizacionRequeridaDialog(resultado: resultado),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('Actualización obligatoria', () {
    const obligatoria = ResultadoActualizacion(
      estado: EstadoActualizacion.obligatoria,
      mensaje: 'Actualiza para seguir usando ArjiPagos',
      urlTienda: urlTienda,
    );

    testWidgets('muestra el mensaje del backend y solo el botón Actualizar',
        (tester) async {
      await montar(tester, obligatoria);

      expect(find.text(AppStrings.actualizacionTituloObligatoria), findsOneWidget);
      expect(find.text('Actualiza para seguir usando ArjiPagos'), findsOneWidget);
      expect(find.text(AppStrings.actualizacionBotonActualizar), findsOneWidget);
      expect(find.text(AppStrings.actualizacionBotonAhoraNo), findsNothing);
    });

    testWidgets('el botón atrás NO lo cierra', (tester) async {
      await montar(tester, obligatoria);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
      expect(cierre, isNull);
    });

    testWidgets('se pinta igual en tema oscuro', (tester) async {
      await montar(tester, obligatoria, tema: ThemeMode.dark);

      expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
      expect(find.text(AppStrings.actualizacionBotonActualizar), findsOneWidget);
    });
  });

  group('Actualización sugerida', () {
    const sugerida = ResultadoActualizacion(
      estado: EstadoActualizacion.sugerida,
      mensaje: 'Hay una versión nueva',
      urlTienda: urlTienda,
    );

    testWidgets('"Ahora no" cierra e informa de que fue el usuario',
        (tester) async {
      await montar(tester, sugerida);

      await tester.tap(find.text(AppStrings.actualizacionBotonAhoraNo));
      await tester.pumpAndSettle();

      expect(find.byType(ActualizacionRequeridaDialog), findsNothing);
      expect(cierre, CierreActualizacion.usuario);
    });

    testWidgets('el atrás lo cierra e informa de que fue el usuario',
        (tester) async {
      // Es la vía que obliga a `canPop: false` con cierre manual: si se dejara
      // que el atrás popeara solo, el resultado sería nulo y el observador lo
      // confundiría con una navegación que se llevó la ruta.
      await montar(tester, sugerida);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ActualizacionRequeridaDialog), findsNothing);
      expect(cierre, CierreActualizacion.usuario);
    });
  });

  group('Mantenimiento', () {
    const mantenimiento = ResultadoActualizacion(
      estado: EstadoActualizacion.mantenimiento,
      mensaje: 'Volvemos en unos minutos',
    );

    testWidgets('solo ofrece Reintentar, sin enlace a la tienda',
        (tester) async {
      await montar(tester, mantenimiento);

      expect(find.text(AppStrings.actualizacionTituloMantenimiento), findsOneWidget);
      expect(find.text(AppStrings.actualizacionBotonReintentar), findsOneWidget);
      expect(find.text(AppStrings.actualizacionBotonActualizar), findsNothing);
    });

    testWidgets('Reintentar cierra pidiendo otra consulta', (tester) async {
      await montar(tester, mantenimiento);

      await tester.tap(find.text(AppStrings.actualizacionBotonReintentar));
      await tester.pumpAndSettle();

      expect(cierre, CierreActualizacion.reintentar);
    });

    testWidgets('el botón atrás NO lo cierra', (tester) async {
      await montar(tester, mantenimiento);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
    });
  });

  group('Sin enlace de tienda', () {
    testWidgets('no se pinta un botón que no lleva a ninguna parte',
        (tester) async {
      await montar(
        tester,
        const ResultadoActualizacion(
          estado: EstadoActualizacion.obligatoria,
          mensaje: 'Actualiza',
        ),
      );

      expect(find.text(AppStrings.actualizacionBotonActualizar), findsNothing);
    });
  });
}
