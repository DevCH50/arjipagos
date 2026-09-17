import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/widgets/imagen_remota.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del hueco de las imágenes remotas.
///
/// Origen: el 2026-09-17 Carlos reportó que en la tirilla de avisos no se veía
/// ningún indicador mientras la portada bajaba, y que la última «se veía rota».
/// Eran dos caras del mismo fallo: tanto el `placeholder` como el `errorWidget`
/// eran un rectángulo de color liso, así que una imagen que tardaba —la del
/// último aviso pesa 300 KB y tardaba varios segundos— era indistinguible de
/// una que había fallado.
///
/// Se prueban [ImagenRemotaCargando] y [ImagenRemotaError] sueltos: montar un
/// `CachedNetworkImage` exigiría una caché falsa, y lo que hay que garantizar
/// es lo que ve el usuario en el hueco.
void main() {
  Widget montar(Widget hijo) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 200, child: hijo)),
  );

  group('Mientras la imagen carga', () {
    testWidgets('se ve el aro de progreso', (WidgetTester tester) async {
      await tester.pumpWidget(montar(const ImagenRemotaCargando()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('sin tamaño total conocido, el aro gira sin marcar avance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar(const ImagenRemotaCargando()));

      final CircularProgressIndicator aro = tester.widget(
        find.byType(CircularProgressIndicator),
      );
      expect(aro.value, isNull);
    });

    testWidgets('con tamaño total conocido, el aro marca el porcentaje', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar(const ImagenRemotaCargando(progreso: 0.4)));

      final CircularProgressIndicator aro = tester.widget(
        find.byType(CircularProgressIndicator),
      );
      expect(aro.value, 0.4);
    });

    testWidgets('se ve la silueta de una imagen, no un rectángulo vacío', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar(const ImagenRemotaCargando()));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.image_outlined))
            .semanticLabel,
        AppStrings.bannersImagenCargando,
      );
    });
  });

  group('Cuando la imagen falla', () {
    testWidgets('se distingue de una que está cargando', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar(const ImagenRemotaError()));

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      // Lo que nunca puede pasar: que un fallo parezca una descarga en curso.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('lo dice también para los lectores de pantalla', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar(const ImagenRemotaError()));

      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.image_not_supported_outlined))
            .semanticLabel,
        AppStrings.bannersImagenNoDisponible,
      );
    });
  });

  group('Quién pinta las portadas de los avisos', () {
    /// Guardián: las dos pantallas que muestran portadas tienen que usar
    /// [ImagenRemota]. Si alguna vuelve a montar un `CachedNetworkImage` a pelo,
    /// se queda otra vez sin indicador y sin aviso de fallo.
    const List<String> pantallas = <String>[
      'lib/src/presentation/pages/banners/widgets/banner_card.dart',
      'lib/src/presentation/pages/banners/widgets/banner_detalle_sheet.dart',
    ];

    for (final String ruta in pantallas) {
      test('${ruta.split('/').last} usa ImagenRemota', () {
        final String codigo = File(ruta).readAsStringSync();

        expect(codigo, contains('ImagenRemota('));
        expect(
          codigo.contains('CachedNetworkImage('),
          isFalse,
          reason: 'Se quedaría sin aro de progreso y sin aviso de fallo',
        );
      });
    }
  });
}
