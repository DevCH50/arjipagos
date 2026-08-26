import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: la preferencia del bloqueo biométrico NO puede vivir en
/// `SharedPref`.
///
/// ## Qué protege
///
/// `AuthRepositoryImpl.logout()` termina con `sharedPref.clear()`. Cualquier
/// cosa guardada ahí **se destruye al cerrar sesión**.
///
/// Para el cerrojo eso significaría que el usuario tiene que volver a activarlo
/// cada vez que cierra sesión. Y cuando se añada el login biométrico —el que
/// deja entrar sin escribir la contraseña— sería fatal: el secreto que sirve
/// para volver a entrar se borraría **justo en el momento en que hace falta**,
/// dejando la función muerta sin que nada fallara de forma visible.
///
/// Es un fallo silencioso, no un crash. Por eso hay un test y no un comentario.
///
/// La forma correcta es `SecureStorage` con claves propias, que es lo que hace
/// `BiometriaStorage`: `clearUserSession()` solo toca `user_session`,
/// `access_token` y `refresh_token`.
void main() {
  /// Archivos que tocan la persistencia de la biometría.
  const List<String> rutasVigiladas = <String>[
    'lib/src/data/dataSource/local/BiometriaStorage.dart',
    'lib/src/data/repository/BiometriaRepositoryImpl.dart',
    'lib/src/domain/useCases/biometria',
    'lib/src/presentation/pages/biometria',
  ];

  /// Recoge los .dart de una ruta, sea archivo o carpeta.
  List<File> archivosDe(String ruta) {
    final File comoArchivo = File(ruta);
    if (comoArchivo.existsSync()) {
      return <File>[comoArchivo];
    }

    final Directory comoCarpeta = Directory(ruta);
    if (!comoCarpeta.existsSync()) {
      return <File>[];
    }

    return comoCarpeta
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();
  }

  /// Quita los comentarios antes de buscar.
  ///
  /// Sin esto el test se dispara con su propia documentación: `BiometriaStorage`
  /// lleva escrito, precisamente, por qué NO usa `SharedPref`. Lo que se vigila
  /// es el código, no las explicaciones.
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

  test('la biometría no se persiste en SharedPref', () {
    final List<String> infractores = <String>[];

    for (final String ruta in rutasVigiladas) {
      for (final File archivo in archivosDe(ruta)) {
        final String contenido = soloCodigo(archivo.readAsStringSync());

        if (contenido.contains('SharedPref') ||
            contenido.contains('shared_preferences')) {
          infractores.add(archivo.path);
        }
      }
    }

    expect(
      infractores,
      isEmpty,
      reason: 'Estos archivos usan SharedPref para la biometría:\n'
          '${infractores.join('\n')}\n\n'
          'AuthRepositoryImpl.logout() hace sharedPref.clear(), así que lo que '
          'se guarde ahí se borra en cada cierre de sesión — que es justo cuando '
          'el login biométrico lo necesita. Usa SecureStorage con claves propias '
          '(ver BiometriaStorage).',
    );
  });

  test('BiometriaStorage se apoya en SecureStorage', () {
    final String contenido =
        File('lib/src/data/dataSource/local/BiometriaStorage.dart')
            .readAsStringSync();

    expect(
      contenido.contains('SecureStorage'),
      isTrue,
      reason: 'BiometriaStorage debe persistir en SecureStorage.',
    );
  });

  test('clearUserSession no borra las claves de biometría', () {
    final String contenido =
        File('lib/src/data/dataSource/local/SecureStorage.dart')
            .readAsStringSync();

    // Se acota al cuerpo del método para no dar por bueno el nombre porque
    // aparezca en un comentario de otra parte del archivo.
    final int inicio = contenido.indexOf('clearUserSession');
    expect(inicio, greaterThan(-1),
        reason: 'SecureStorage debe seguir teniendo clearUserSession.');

    final int fin = contenido.indexOf('}', inicio);
    final String cuerpo = contenido.substring(inicio, fin);

    expect(
      cuerpo.contains('biometria'),
      isFalse,
      reason: 'clearUserSession() no debe borrar las claves de biometría: la '
          'preferencia del cerrojo sobrevive al cierre de sesión a propósito.',
    );
  });
}
