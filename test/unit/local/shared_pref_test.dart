/// Tests unitarios para SharedPref.
///
/// Blindan la serialización de tipos (Map/List/primitivos) ante breaking
/// changes de `shared_preferences`. Se usa el mock oficial
/// `SharedPreferences.setMockInitialValues` — no toca la plataforma real.
library;

import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPref sharedPref;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sharedPref = SharedPref();
  });

  group('save/read de primitivos', () {
    test('guarda y lee un String', () async {
      await sharedPref.save('nombre', 'Carlos');
      expect(await sharedPref.read('nombre'), 'Carlos');
    });

    test('guarda y lee un int', () async {
      await sharedPref.save('edad', 30);
      expect(await sharedPref.read('edad'), 30);
    });

    test('guarda y lee un bool', () async {
      await sharedPref.save('activo', true);
      expect(await sharedPref.read('activo'), true);
    });

    test('guarda y lee un double', () async {
      await sharedPref.save('saldo', 12.5);
      expect(await sharedPref.read('saldo'), 12.5);
    });

    test('lanza excepción ante un tipo no soportado', () async {
      expect(
        () => sharedPref.save('obj', DateTime(2024)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('serialización JSON de Map y List', () {
    test('guarda un Map y read lo devuelve deserializado', () async {
      final mapa = {'id': 1, 'nombre': 'Ana'};
      await sharedPref.save('user', mapa);

      final leido = await sharedPref.read('user');
      expect(leido, isA<Map>());
      expect(leido['nombre'], 'Ana');
    });

    test('guarda una List y read la devuelve deserializada', () async {
      await sharedPref.save('ids', [1, 2, 3]);

      final leido = await sharedPref.read('ids');
      expect(leido, [1, 2, 3]);
    });

    test('readMap devuelve el Map guardado', () async {
      await sharedPref.save('sesion', {'token': 'abc'});
      final mapa = await sharedPref.readMap('sesion');
      expect(mapa, {'token': 'abc'});
    });

    test('readMap devuelve null si el valor no es JSON de objeto', () async {
      await sharedPref.save('texto', 'no-es-json');
      expect(await sharedPref.readMap('texto'), isNull);
    });

    test('readMap devuelve null si la key no existe', () async {
      expect(await sharedPref.readMap('inexistente'), isNull);
    });
  });

  group('operaciones auxiliares', () {
    test('readString devuelve el string guardado', () async {
      await sharedPref.save('saludo', 'hola');
      expect(await sharedPref.readString('saludo'), 'hola');
    });

    test('contains detecta existencia de la key', () async {
      await sharedPref.save('k', 'v');
      expect(await sharedPref.contains('k'), true);
      expect(await sharedPref.contains('otra'), false);
    });

    test('remove elimina la key', () async {
      await sharedPref.save('k', 'v');
      await sharedPref.remove('k');
      expect(await sharedPref.contains('k'), false);
    });

    test('clear elimina todas las keys', () async {
      await sharedPref.save('a', '1');
      await sharedPref.save('b', '2');
      await sharedPref.clear();
      expect(await sharedPref.contains('a'), false);
      expect(await sharedPref.contains('b'), false);
    });
  });
}
