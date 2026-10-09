/// Test guardián: ningún archivo de `lib/` escribe en consola por su cuenta.
///
/// `debugPrint` y `print` **escriben también en Release**. El botón Run de
/// Xcode usa Release, y una app publicada también: lo que se imprime ahí acaba
/// en el registro del sistema del teléfono. Pasó el 2026-10-08 en el iPhone 17:
/// la respuesta del cobro (`Respuesta JSON: {...}`) salía en la consola de
/// Xcode, cuando con Release no debería salir ni una línea de la app.
///
/// Todo va por `AppLogger`, que solo habla en Debug. Su `_log` es el único
/// sitio autorizado a llamar a `debugPrint`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ no llama a print ni a debugPrint fuera de AppLogger', () {
    final llamada = RegExp(r'\b(print|debugPrint)\(');
    final infractores = <String>[];

    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('app_logger.dart'));

    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trimLeft();
        if (!linea.startsWith('//') && llamada.hasMatch(linea)) {
          infractores.add('${archivo.path}:${i + 1}  $linea');
        }
      }
    }

    expect(
      infractores,
      isEmpty,
      reason: 'Usa AppLogger en lugar de print/debugPrint:\n'
          '${infractores.join('\n')}',
    );
  });
}
