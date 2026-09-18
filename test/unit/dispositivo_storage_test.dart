/// Tests de `DispositivoStorage`, el dueño del `device_id` del teléfono.
///
/// Se monta sobre el `SecureStorage` **de verdad**, con el almacén en memoria
/// que ofrece `flutter_secure_storage` para tests. Así `clearUserSession()` es
/// el de producción y no un mock que diga lo que uno quiera oír: si algún día
/// empezara a borrar más de la cuenta, este test lo cazaría.
library;

import 'package:arjipagos/src/data/dataSource/local/DispositivoStorage.dart';
import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorage secureStorage;
  late DispositivoStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    secureStorage = SecureStorage();
    storage = DispositivoStorage(secureStorage);
  });

  test('la primera vez genera un id y lo guarda', () async {
    final String id = await storage.obtenerDeviceId();

    expect(id, isNotEmpty);
    expect(await secureStorage.read(DispositivoStorage.claveDeviceId), id);
  });

  test('nunca regenera: llamadas sucesivas devuelven el mismo id', () async {
    final String primero = await storage.obtenerDeviceId();
    final String segundo = await storage.obtenerDeviceId();
    final String tercero = await DispositivoStorage(secureStorage)
        .obtenerDeviceId();

    expect(segundo, primero);
    expect(tercero, primero,
        reason: 'Otra instancia del almacén debe leer el mismo id, no crear '
            'uno: el locator entrega una instancia nueva en cada llamada.');
  });

  test('sobrevive al cierre de sesión', () async {
    final String antes = await storage.obtenerDeviceId();

    await secureStorage.clearUserSession();

    expect(await storage.obtenerDeviceId(), antes,
        reason: 'Si el logout se llevara el id, el siguiente login crearía '
            'otra fila en el backend: justo el fallo que esto cierra.');
  });

  test('respeta un id que ya existía', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      DispositivoStorage.claveDeviceId: 'id-de-antes',
    });

    expect(
      await DispositivoStorage(SecureStorage()).obtenerDeviceId(),
      'id-de-antes',
    );
  });

  test('un valor vacío no sirve de clave y se rehace', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      DispositivoStorage.claveDeviceId: '',
    });

    final String id =
        await DispositivoStorage(SecureStorage()).obtenerDeviceId();

    expect(id, isNotEmpty);
  });
}
