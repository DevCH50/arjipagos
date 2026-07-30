import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_pago_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

/// Tests de `CarritoPagoItem`.
///
/// El foco está en el desbordamiento horizontal: la versión anterior usaba
/// `ListTile`, cuyo `trailing` recibe un ancho acotado, y el importe junto al
/// botón de quitar desbordaban por fracciones de pixel en pantallas angostas
/// (banner "RIGHT OVERFLOWED BY 0.853 PIXELS"). Estos tests fijan el ancho de
/// pantalla y verifican que no se lance ninguna excepción de layout.
void main() {
  /// Anchos lógicos de los dispositivos más angostos soportados.
  ///
  /// 320 = iPhone SE (1ª gen) / Android compactos, 375 = iPhone SE (2ª/3ª gen),
  /// 360 = ancho más común en Android.
  const anchosAngostos = <double>[320, 360, 375];

  /// Monta el widget con un ancho de pantalla fijo y un factor de texto dado.
  Future<void> montar(
    WidgetTester tester, {
    required double ancho,
    required EstadoDeCuenta pago,
    bool puedeEliminar = true,
    double escalaTexto = 1.0,
    Brightness brillo = Brightness.light,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(ancho, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brillo, useMaterial3: true),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(escalaTexto),
            ),
            child: CarritoPagoItem(
              alumnoId: 1,
              pago: pago,
              puedeEliminar: puedeEliminar,
            ),
          ),
        ),
      ),
    );
  }

  group('CarritoPagoItem - renderizado', () {
    testWidgets('muestra descripción, importe y botón de quitar',
        (tester) async {
      final pago = TestEstadoDeCuenta.pendiente;
      await montar(tester, ancho: 375, pago: pago);

      expect(find.text(pago.descripcionAbreviada), findsOneWidget);
      expect(find.text(pago.totalFormatted), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('el botón queda deshabilitado si no se puede eliminar',
        (tester) async {
      await montar(
        tester,
        ancho: 375,
        pago: TestEstadoDeCuenta.pendiente,
        puedeEliminar: false,
      );

      final boton = tester.widget<IconButton>(find.byType(IconButton));
      expect(boton.onPressed, isNull);
    });
  });

  group('CarritoPagoItem - sin desbordamiento horizontal', () {
    for (final ancho in anchosAngostos) {
      testWidgets('no desborda a $ancho px de ancho', (tester) async {
        await montar(tester, ancho: ancho, pago: TestEstadoDeCuenta.pendiente);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no desborda con importe y descripción largos', (tester) async {
      final pago = EstadoDeCuenta(
        id: 3,
        cicloId: TestEstadoDeCuenta.cicloActual,
        nivelId: 1,
        descripcionCorta: 'Colegiatura Septiembre 2024 con recargo por mora',
        total: 1234567.89,
        totalFormatted: '\$1,234,567.89',
        fechaVencimiento: '2024-09-30',
        estadoPago: EstadoPago.vencido,
        numPago: 3,
        numPagoActivo: true,
        aceptaPagosDiversos: true,
        estaDisponibleEnInternet: true,
        facturaPdf: '',
        facturaXml: '',
      );

      await montar(tester, ancho: 320, pago: pago);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no desborda con el texto ampliado por accesibilidad',
        (tester) async {
      await montar(
        tester,
        ancho: 320,
        pago: TestEstadoDeCuenta.pendiente,
        escalaTexto: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CarritoPagoItem - tema oscuro', () {
    testWidgets('renderiza sin desbordar en tema oscuro', (tester) async {
      await montar(
        tester,
        ancho: 320,
        pago: TestEstadoDeCuenta.pendiente,
        brillo: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(TestEstadoDeCuenta.pendiente.totalFormatted),
          findsOneWidget);
    });

    testWidgets('el ícono de quitar usa el color de error del tema oscuro',
        (tester) async {
      await montar(
        tester,
        ancho: 375,
        pago: TestEstadoDeCuenta.pendiente,
        brillo: Brightness.dark,
      );

      final contexto = tester.element(find.byType(CarritoPagoItem));
      final icono = tester.widget<Icon>(
        find.byIcon(Icons.remove_circle_outline),
      );
      expect(icono.color, Theme.of(contexto).colorScheme.error);
    });
  });
}
