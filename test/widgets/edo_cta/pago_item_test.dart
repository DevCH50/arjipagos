/// Tests de layout de `PagoItem` (Pagos Pendientes).
///
/// El monto y el número de pago formaban antes una columna a la derecha que
/// competía por el ancho: al concepto le quedaba tan poco que se partía en dos
/// líneas y la fecha de vencimiento se cortaba con puntos suspensivos. Estos
/// tests fijan el ancho de pantalla y verifican que la fecha se lea completa,
/// que el concepto conserve el mismo tamaño en todos los renglones —encoger
/// solo el más largo dejaba la lista despareja— y que nada desborde, tampoco
/// con la escala de fuente del sistema aumentada.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/pago_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  /// Anchos lógicos de los dispositivos más angostos soportados.
  ///
  /// 320 = iPhone SE (1ª gen) / Android compactos, 375 = iPhone SE (2ª/3ª gen),
  /// 360 = ancho más común en Android (el del OPPO de pruebas).
  const anchosAngostos = <double>[320, 360, 375];

  late MockSharedPref mockSharedPref;

  setUp(() {
    mockSharedPref = MockSharedPref();
    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  /// Monta el item con un ancho de pantalla fijo y la escala de texto dada.
  Future<void> montar(
    WidgetTester tester, {
    required double ancho,
    required EstadoDeCuenta pago,
    double escalaTexto = 1.0,
    Brightness brillo = Brightness.light,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(ancho, 800);
    addTearDown(tester.view.reset);

    final bloc = EdoCtaListBloc(
      createMockEdoCtaUseCases(),
      SeleccionPagosStorage(
        mockSharedPref,
        claveSeleccion: 'seleccion_pagos_ef1',
      ),
      emisorFiscalId: 1,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brillo == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(escalaTexto)),
            child: BlocProvider<EdoCtaListBloc>.value(
              value: bloc,
              child: PagoItem(
                alumno: TestAlumno.activo,
                pago: pago,
                pagosDisponibles: [pago],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('PagoItem — no desborda', () {
    for (final ancho in anchosAngostos) {
      testWidgets('a $ancho px de ancho', (tester) async {
        await montar(tester, ancho: ancho, pago: TestEstadoDeCuenta.pendiente);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('con la fuente del sistema al doble', (tester) async {
      await montar(
        tester,
        ancho: 360,
        pago: TestEstadoDeCuenta.pendiente,
        escalaTexto: 2.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('en tema oscuro', (tester) async {
      await montar(
        tester,
        ancho: 360,
        pago: TestEstadoDeCuenta.pendiente,
        brillo: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'dentro de un Column con alto sin acotar, como en la lista real',
      (tester) async {
        // Este es el contexto de verdad: `PagosList` mete los renglones en un
        // `Column` que vive dentro de un scroll, así que al renglón le llega el
        // alto SIN acotar. Montarlo suelto bajo el `Scaffold` le da el alto de
        // la pantalla y esconde justo los fallos que dependen de eso —fue lo que
        // dejó pasar un renglón que en el dispositivo no se pintaba—.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 800);
        addTearDown(tester.view.reset);

        final bloc = EdoCtaListBloc(
          createMockEdoCtaUseCases(),
          SeleccionPagosStorage(
            mockSharedPref,
            claveSeleccion: 'seleccion_pagos_ef1',
          ),
          emisorFiscalId: 1,
        );
        addTearDown(bloc.close);

        final pago = TestEstadoDeCuenta.pendiente;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    BlocProvider<EdoCtaListBloc>.value(
                      value: bloc,
                      child: PagoItem(
                        alumno: TestAlumno.activo,
                        pago: pago,
                        pagosDisponibles: [pago],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        // Y además se ve: un renglón de alto cero no sirve de nada.
        expect(find.text(pago.descripcionCompleta), findsOneWidget);
        expect(tester.getSize(find.byType(PagoItem)).height, greaterThan(0));
      },
    );
  });

  group('PagoItem — el texto se lee completo', () {
    testWidgets('la fecha de vencimiento no se recorta', (tester) async {
      final pago = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 360, pago: pago);

      final fecha = tester.widget<Text>(
        find.text('${AppStrings.edoCtaVence} ${pago.fechaVencimiento}'),
      );

      // Sin ellipsis: si no cabe se encoge, nunca se corta.
      expect(fecha.overflow, isNot(TextOverflow.ellipsis));
      expect(fecha.maxLines, 1);
    });

    testWidgets('el concepto nunca se recorta', (tester) async {
      final pago = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 320, pago: pago);

      final concepto = tester.widget<Text>(find.text(pago.descripcionCompleta));

      // Sin tope de líneas y sin puntos suspensivos: el concepto envuelve las
      // líneas que haga falta, pero no hay ninguna vía por la que pueda quedar
      // cortado. Tampoco se encoge con un `FittedBox`.
      expect(concepto.maxLines, isNull);
      expect(concepto.overflow, isNot(TextOverflow.ellipsis));
      expect(concepto.style?.overflow, isNot(TextOverflow.ellipsis));
      expect(
        find.ancestor(
          of: find.text(pago.descripcionCompleta),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('el concepto mide igual sea corto o largo', (tester) async {
      // Congruencia tipográfica entre renglones: la lista no puede tener un
      // concepto a 16 px y el de al lado a 14 según lo que mida cada texto.
      // Hasta el 2026-08-28 sí pasaba, porque el concepto bajaba por una rampa
      // (16 → 14 → 12) para caber en una línea. Ahora el tamaño es fijo y lo
      // que cede es la altura del renglón.
      final corto = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 320, pago: corto);
      final estiloCorto = tester
          .widget<Text>(find.text(corto.descripcionCompleta))
          .style;

      final largo = TestEstadoDeCuenta.vencido;
      await montar(tester, ancho: 320, pago: largo);
      final estiloLargo = tester
          .widget<Text>(find.text(largo.descripcionCompleta))
          .style;

      expect(estiloLargo?.fontSize, equals(estiloCorto?.fontSize));
      // Y es el escalón de cuerpo del tema, no un número escrito a mano.
      expect(estiloCorto?.fontSize, equals(16.0));
    });

    testWidgets('el monto y el número de pago siguen visibles', (tester) async {
      final pago = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 320, pago: pago);

      expect(find.text(pago.totalFormatted), findsOneWidget);
      expect(
        find.text('${AppStrings.edoCtaPagoNum}${pago.numPago}'),
        findsOneWidget,
      );
    });

    testWidgets('el chip de estado conserva su tamaño natural', (tester) async {
      // En un `Expanded` la píldora se estiraba a todo el ancho del renglón.
      const ancho = 360.0;
      await montar(tester, ancho: ancho, pago: TestEstadoDeCuenta.pendiente);

      final anchoChip = tester.getSize(find.byType(EstadoPagoChip)).width;

      expect(anchoChip, lessThan(ancho / 2));
    });

    testWidgets('el importe mide igual que el concepto y va en negrita', (
      tester,
    ) async {
      // Congruencia tipográfica: el importe destaca por peso y color, no por
      // ser un escalón más grande que el concepto.
      final pago = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 360, pago: pago);

      final concepto = tester.widget<Text>(find.text(pago.descripcionCompleta));
      final monto = tester.widget<Text>(find.text(pago.totalFormatted));

      expect(monto.style?.fontSize, concepto.style?.fontSize);
      expect(monto.style?.fontWeight, FontWeight.bold);
    });
  });
}
