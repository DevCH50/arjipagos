import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: impide que vuelva a filtrarse una excepción técnica al usuario.
///
/// Origen: incidente del 2026-08-13. Un `HandshakeException` por cadena TLS
/// incompleta llegó crudo al AlertDialog de login porque los Services hacían
/// `return Error(e.toString())`.
///
/// Este test escanea el código fuente de los Services y falla si alguien vuelve
/// a construir un `Error(...)` a partir del `toString()` de una excepción.
/// La forma correcta es `Error(mensajeErrorRed(e))`.
void main() {
  const rutaServices = 'lib/src/data/dataSource/remote/services';

  /// Detecta `Error(e.toString())` y variantes con genérico:
  /// `Error<bool>(error.toString())`, `Error<List<X>>(ex.toString())`.
  final patronFuga = RegExp(
    r'Error(<[^(]*>)?\(\s*[A-Za-z_][A-Za-z0-9_]*\.toString\(\)\s*\)',
  );

  test('ningún Service construye un Error a partir de e.toString()', () {
    final directorio = Directory(rutaServices);
    expect(
      directorio.existsSync(),
      isTrue,
      reason: 'No se encontró $rutaServices — ¿se movieron los Services?',
    );

    final archivos = directorio
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(archivos, isNotEmpty, reason: 'No hay Services que revisar');

    final fugas = <String>[];

    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        if (patronFuga.hasMatch(lineas[i])) {
          fugas.add('${archivo.path}:${i + 1} → ${lineas[i].trim()}');
        }
      }
    }

    expect(
      fugas,
      isEmpty,
      reason: 'Estos Services filtran la excepción cruda al usuario.\n'
          'Usa Error(mensajeErrorRed(e)) en su lugar:\n'
          '${fugas.join('\n')}',
    );
  });

  test('el patrón guardián realmente detecta la fuga (autocomprobación)', () {
    // Si el regex dejara de funcionar, el test anterior pasaría siempre
    // aunque hubiera fugas. Esto verifica que sigue detectando.
    expect(patronFuga.hasMatch('      return Error(e.toString());'), isTrue);
    expect(patronFuga.hasMatch('      return Error<bool>(e.toString());'), isTrue);
    expect(
      patronFuga.hasMatch('      return Error<List<Notificacion>>(e.toString());'),
      isTrue,
    );

    // Y que no marca como fuga el uso correcto.
    expect(patronFuga.hasMatch('      return Error(mensajeErrorRed(e));'), isFalse);
    expect(
      patronFuga.hasMatch("        {'page': page.toString()},"),
      isFalse,
    );
  });
}
