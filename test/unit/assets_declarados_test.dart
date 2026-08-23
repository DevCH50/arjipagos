/// Verifica que los assets que carga el código estén declarados en pubspec.
///
/// Desde que `pubspec.yaml` declara los assets **archivo por archivo** en vez de
/// la carpeta entera (para no empaquetar 34 MB de insumos de diseño), olvidarse
/// de dar de alta un archivo nuevo deja la app compilando pero reventando en
/// tiempo de ejecución con "Unable to load asset". Este test lo caza antes.
///
/// **Al añadir un asset nuevo:** hay que darlo de alta en `pubspec.yaml` y
/// añadirlo aquí.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Assets que el código Dart carga por ruta literal.
  ///
  /// - `logo_arji.png`: SplashPage y LogoRedondoUno (login).
  /// - `background_shopping.jpg`: fondo de Login y Registro (BackgroundImage).
  const assetsEnUso = <String>[
    'assets/arji/logo_arji.png',
    'assets/img/background_shopping.jpg',
  ];

  group('Assets declarados en pubspec', () {
    for (final ruta in assetsEnUso) {
      test('$ruta está empaquetado y no viene vacío', () async {
        final datos = await rootBundle.load(ruta);

        expect(datos.lengthInBytes, greaterThan(0),
            reason: '$ruta se resolvió pero llegó vacío');
      });
    }

    test('un asset no declarado sí falla', () async {
      // Comprueba que el test anterior mide algo de verdad: si el bundle de
      // pruebas resolviera cualquier ruta, no estaría protegiendo nada.
      expect(
        () => rootBundle.load('assets/img/no_existe_a_proposito.png'),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
