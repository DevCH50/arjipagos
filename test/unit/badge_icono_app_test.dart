/// Tests de [BadgeIconoApp] — el globo rojo del icono en iOS.
///
/// Lo que se comprueba aquí es el **contrato con el lado nativo**: el nombre del
/// canal, el del método y la forma del argumento. Si alguien los cambia en Dart
/// sin tocar `ios/Runner/AppDelegate.swift` —o al revés— el globo deja de
/// funcionar en silencio, porque `fijar` se traga los fallos a propósito.
///
/// El envío real solo ocurre en iOS, así que las pruebas fuerzan la plataforma
/// con `debugDefaultTargetPlatformOverride` y escuchan el canal con el
/// messenger de pruebas, sin necesidad de un dispositivo.
library;

import 'package:arjipagos/src/data/dataSource/local/BadgeIconoApp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Debe coincidir con el nombre declarado en `AppDelegate.swift`.
  const canal = MethodChannel('mx.moriah.arjipagos/badge');

  /// Llamadas que llegarían al lado nativo durante cada prueba.
  late List<MethodCall> recibidas;

  /// Instala un oyente en el canal y devuelve la lista donde se acumulan.
  void escucharCanal() {
    recibidas = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async {
      recibidas.add(call);
      return null;
    });
  }

  setUp(escucharCanal);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('en iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('manda el método y la cantidad que espera AppDelegate.swift', () async {
      await BadgeIconoApp.fijar(7);

      expect(recibidas, hasLength(1));
      expect(recibidas.single.method, 'fijar');
      expect(recibidas.single.arguments, {'cantidad': 7});
    });

    test('el cero viaja igual: es como se apaga el globo', () async {
      await BadgeIconoApp.fijar(0);

      expect(recibidas.single.arguments, {'cantidad': 0});
    });

    test('una cantidad negativa se convierte en cero, no se manda tal cual',
        () async {
      // iOS no sabe pintar un globo negativo. Sanearlo aquí evita que un conteo
      // descuadrado —por ejemplo, un decremento optimista de más— llegue al
      // lado nativo.
      await BadgeIconoApp.fijar(-3);

      expect(recibidas.single.arguments, {'cantidad': 0});
    });
  });

  group('fuera de iOS', () {
    test('en Android no se llama al canal', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await BadgeIconoApp.fijar(5);

      // Android no tiene un contador de sistema equivalente: cada capa de
      // personalización lo resuelve a su manera, así que no hay nada que decir.
      expect(recibidas, isEmpty);
    });
  });
}
