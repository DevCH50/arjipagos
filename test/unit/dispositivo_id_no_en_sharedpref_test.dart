import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: el `device_id` NO puede vivir en `SharedPref`.
///
/// ## Qué protege
///
/// `AuthRepositoryImpl.logout()` termina con `sharedPref.clear()`. Si el id se
/// guardara ahí, se borraría **en cada cierre de sesión**, y el siguiente login
/// generaría uno nuevo. El backend vería un aparato distinto y crearía otra
/// fila: exactamente el problema que el `device_id` vino a cerrar —los tokens
/// de sobra que Firebase sigue dando por vivos—, pero con el código puesto y la
/// sensación de estar arreglado.
///
/// Es un fallo silencioso, no un crash. Por eso hay un test y no un comentario.
///
/// Calcado de `biometria_no_en_sharedpref_test.dart`, que vigila lo mismo para
/// la preferencia del bloqueo biométrico.
void main() {
  const String rutaAlmacen =
      'lib/src/data/dataSource/local/DispositivoStorage.dart';

  /// Quita los comentarios antes de buscar: `DispositivoStorage` explica en su
  /// documentación, precisamente, por qué NO usa `SharedPref`.
  String soloCodigo(String contenido) {
    return contenido
        .split('\n')
        .where((String linea) {
          final String limpia = linea.trimLeft();
          return !limpia.startsWith('//') &&
              !limpia.startsWith('*') &&
              !limpia.startsWith('/*');
        })
        .join('\n');
  }

  test('el device_id no se persiste en SharedPref', () {
    final String codigo = soloCodigo(File(rutaAlmacen).readAsStringSync());

    expect(
      codigo.contains('SharedPref') || codigo.contains('shared_preferences'),
      isFalse,
      reason: 'DispositivoStorage usa SharedPref. AuthRepositoryImpl.logout() '
          'hace sharedPref.clear(), así que el id se borraría en cada cierre de '
          'sesión y el backend crearía una fila nueva por login. Usa '
          'SecureStorage con una clave propia.',
    );
  });

  test('DispositivoStorage se apoya en SecureStorage', () {
    final String codigo = soloCodigo(File(rutaAlmacen).readAsStringSync());

    expect(codigo.contains('SecureStorage'), isTrue);
  });

  test('clearUserSession no borra la clave del device_id', () {
    final String contenido =
        File('lib/src/data/dataSource/local/SecureStorage.dart')
            .readAsStringSync();

    final int inicio = contenido.indexOf('clearUserSession');
    expect(inicio, greaterThan(-1),
        reason: 'SecureStorage debe seguir teniendo clearUserSession.');

    final String cuerpo =
        contenido.substring(inicio, contenido.indexOf('}', inicio));

    expect(
      cuerpo.contains('dispositivo') || cuerpo.contains('deleteAll'),
      isFalse,
      reason: 'clearUserSession() no debe tocar el device_id: tiene que '
          'sobrevivir al cierre de sesión para que el siguiente login '
          'actualice la fila del aparato en vez de crear otra.',
    );
  });
}
