/// Tests de `generarUuidV4`, el generador propio del identificador del teléfono.
///
/// Lo que se fija aquí es lo que el backend necesita: un texto con la forma
/// canónica de un UUID v4, que no pase de 191 caracteres (el tamaño de la
/// columna `device_id`) y que no se repita entre instalaciones.
library;

import 'package:arjipagos/src/core/utils/uuid_v4.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Forma canónica: 8-4-4-4-12 hexadecimales en minúscula, con el 4 de la
  /// versión en su sitio y la variante RFC 4122 (8, 9, a o b).
  final RegExp formaV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  group('generarUuidV4', () {
    test('tiene la forma canónica de un UUID versión 4', () {
      for (int i = 0; i < 200; i++) {
        final String uuid = generarUuidV4();
        expect(uuid, matches(formaV4), reason: 'No es un UUID v4: $uuid');
      }
    });

    test('mide 36 caracteres, muy por debajo de los 191 de la columna', () {
      expect(generarUuidV4().length, 36);
    });

    test('mil llamadas no repiten ni un valor', () {
      final Set<String> vistos = <String>{
        for (int i = 0; i < 1000; i++) generarUuidV4(),
      };

      expect(vistos.length, 1000);
    });
  });
}
