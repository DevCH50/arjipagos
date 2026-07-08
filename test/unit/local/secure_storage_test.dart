/// Tests unitarios para SecureStorage.
///
/// Blindan la lógica Dart de serialización JSON y los helpers de sesión ante
/// breaking changes de `flutter_secure_storage`. Se mockea el MethodChannel del
/// plugin con un store en memoria (no valida el keychain/keystore nativo, que
/// solo se puede comprobar en dispositivo).
library;

import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> store = <String, String>{};
  late SecureStorage secureStorage;

  setUp(() {
    store.clear();
    // Mock en memoria del canal nativo de flutter_secure_storage.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'write':
          store[args!['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return store[args!['key'] as String];
        case 'delete':
          store.remove(args!['key'] as String);
          return null;
        case 'containsKey':
          return store.containsKey(args!['key'] as String);
        case 'deleteAll':
          store.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        default:
          return null;
      }
    });
    secureStorage = SecureStorage();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('operaciones básicas', () {
    test('write luego read devuelve el valor', () async {
      await secureStorage.write('k', 'secreto');
      expect(await secureStorage.read('k'), 'secreto');
    });

    test('read de una key inexistente devuelve null', () async {
      expect(await secureStorage.read('nope'), isNull);
    });

    test('delete elimina el valor', () async {
      await secureStorage.write('k', 'v');
      await secureStorage.delete('k');
      expect(await secureStorage.read('k'), isNull);
    });

    test('containsKey refleja la existencia', () async {
      await secureStorage.write('k', 'v');
      expect(await secureStorage.containsKey('k'), true);
      expect(await secureStorage.containsKey('otra'), false);
    });

    test('deleteAll limpia todo', () async {
      await secureStorage.write('a', '1');
      await secureStorage.write('b', '2');
      await secureStorage.deleteAll();
      expect(await secureStorage.read('a'), isNull);
      expect(await secureStorage.read('b'), isNull);
    });
  });

  group('serialización JSON', () {
    test('writeJson/readJson hace round-trip de un Map', () async {
      final data = {'id': 7, 'nombre': 'Ana', 'activo': true};
      await secureStorage.writeJson('perfil', data);

      expect(await secureStorage.readJson('perfil'), data);
    });

    test('readJson devuelve null y borra el valor si está corrupto', () async {
      // Se escribe un string que no es JSON válido directamente en el store.
      await secureStorage.write('corrupto', 'esto-no-es-json');

      expect(await secureStorage.readJson('corrupto'), isNull);
      // El valor corrupto debe haberse eliminado.
      expect(await secureStorage.read('corrupto'), isNull);
    });

    test('readJson de key inexistente devuelve null', () async {
      expect(await secureStorage.readJson('nada'), isNull);
    });
  });

  group('helpers de sesión', () {
    test('saveUserSession/getUserSession hace round-trip', () async {
      final session = {'user_id': 1, 'token': 'abc'};
      await secureStorage.saveUserSession(session);

      expect(await secureStorage.getUserSession(), session);
    });

    test('clearUserSession elimina sesión y tokens', () async {
      await secureStorage.saveUserSession({'user_id': 1});
      await secureStorage.saveAccessToken('token-123');

      await secureStorage.clearUserSession();

      expect(await secureStorage.getUserSession(), isNull);
      expect(await secureStorage.getAccessToken(), isNull);
    });

    test('saveAccessToken/getAccessToken hace round-trip', () async {
      await secureStorage.saveAccessToken('jwt-xyz');
      expect(await secureStorage.getAccessToken(), 'jwt-xyz');
    });
  });
}
