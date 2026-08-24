import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: impide volver a montar un segundo `MyApp` dentro del árbol.
///
/// Origen: incidente del 2026-08-24. El cierre de sesión navegaba con
/// `pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MyApp()), ...)`,
/// tanto en el drawer como al terminar de cambiar la contraseña.
///
/// Eso monta un SEGUNDO `MaterialApp` dentro del que ya está corriendo. Ambos
/// declaran el mismo `navigatorKey` (`appNavigatorKey`, un GlobalKey), así que
/// Flutter reparenta el `Navigator` existente hacia dentro del nuevo
/// `MaterialApp`… que vive dentro de una ruta de ese mismo `Navigator`. El
/// árbol queda cíclico y `redepthChildren` desborda la pila:
///
///   I flutter : Stack Overflow
///   I flutter : #3  SlottedContainerRenderObjectMixin.redepthChildren
///
/// Reventaba igual en Android y en iOS, porque el fallo es de Dart.
///
/// La forma correcta de volver al login es navegar a la ruta con nombre:
/// `Navigator.restorablePushNamedAndRemoveUntil(context, 'login', (r) => false)`.
///
/// `MyApp` solo debe instanciarse en el `runApp` de `lib/main.dart`.
void main() {
  /// `const MyApp()` o `MyApp()`, con o sin `const` delante.
  final patronMyApp = RegExp(r'\bMyApp\s*\(');

  test('MyApp solo se instancia en runApp, nunca dentro de una ruta', () {
    final infractores = <String>[];

    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // El único sitio legítimo: `runApp(const MyApp())`.
        .where((f) => f.path != 'lib/main.dart');

    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i];
        // Ignorar comentarios: esta misma explicación menciona `MyApp`.
        if (linea.trimLeft().startsWith('//')) {
          continue;
        }
        if (patronMyApp.hasMatch(linea)) {
          infractores.add('${archivo.path}:${i + 1}: ${linea.trim()}');
        }
      }
    }

    expect(
      infractores,
      isEmpty,
      reason: 'Se instancia MyApp fuera de lib/main.dart. Montar un segundo '
          'MaterialApp dentro del árbol provoca Stack Overflow por el '
          'GlobalKey compartido del navigatorKey. Para volver al login usa '
          "Navigator.restorablePushNamedAndRemoveUntil(context, 'login', "
          '(r) => false).\n${infractores.join('\n')}',
    );
  });
}
