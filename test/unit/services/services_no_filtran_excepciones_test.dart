import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: impide que vuelva a filtrarse una excepción técnica al usuario.
///
/// Origen: incidente del 2026-08-13. Un `HandshakeException` por cadena TLS
/// incompleta llegó crudo al AlertDialog de login porque los Services hacían
/// `return Error(e.toString())`.
///
/// Escanea Services, repositorios y BLoCs, y falla si un mensaje destinado al
/// usuario se construye a partir de la excepción. La forma correcta es
/// `mensajeErrorRed(e)`, dejando el detalle técnico en `AppLogger`.
void main() {
  /// Carpetas donde se construyen mensajes que acaban en pantalla.
  const rutas = [
    'lib/src/data/dataSource/remote/services',
    'lib/src/data/repository',
    'lib/src/presentation/pages',
  ];

  /// `Error(e.toString())`, con o sin genérico:
  /// `Error<bool>(error.toString())`, `Error<List<X>>(ex.toString())`.
  final patronToString = RegExp(
    r'Error(<[^(]*>)?\(\s*[A-Za-z_][A-Za-z0-9_]*\.toString\(\)\s*\)',
  );

  /// Interpolación de la excepción dentro de un literal:
  /// `'Error inesperado: $e'`, `"fallo ${e}"`.
  /// Fue el patrón que se escapó del guardián en su primera versión.
  final patronInterpolacion = RegExp(r'''['"][^'"]*\$\{?e\b''');

  /// Inicio de una llamada de log: ahí sí puede ir el detalle técnico.
  bool abreLog(String linea) =>
      linea.contains('AppLogger.') || linea.contains('debugPrint(');

  /// Recorre el archivo marcando qué líneas pertenecen a una llamada de log,
  /// incluidas las continuaciones cuando la llamada ocupa varias líneas
  /// (`AppLogger.error(\n  'fallo: $e',\n  tag: 'X');`).
  List<bool> lineasDeLog(List<String> lineas) {
    final marcas = List<bool>.filled(lineas.length, false);
    var dentroDeLog = false;

    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i];
      if (dentroDeLog || abreLog(linea)) {
        marcas[i] = true;
        // La llamada sigue abierta hasta que se cierra con ');'
        dentroDeLog = !linea.contains(');');
      }
    }
    return marcas;
  }

  List<File> dartsDe(String ruta) {
    final dir = Directory(ruta);
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  test('ningún mensaje al usuario se construye desde la excepción', () {
    final archivos = [for (final ruta in rutas) ...dartsDe(ruta)];

    expect(
      archivos,
      isNotEmpty,
      reason: 'No se encontró código que revisar — ¿cambiaron las rutas?',
    );

    final fugas = <String>[];

    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      final esLog = lineasDeLog(lineas);
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i];
        if (esLog[i]) {
          continue;
        }

        if (patronToString.hasMatch(linea) ||
            patronInterpolacion.hasMatch(linea)) {
          fugas.add('${archivo.path}:${i + 1} → ${linea.trim()}');
        }
      }
    }

    expect(
      fugas,
      isEmpty,
      reason: 'Estos sitios filtran la excepción cruda al usuario.\n'
          'Usa mensajeErrorRed(e) y deja el detalle en AppLogger:\n'
          '${fugas.join('\n')}',
    );
  });

  test('los patrones guardianes siguen detectando (autocomprobación)', () {
    // Si los regex se degradaran, el test anterior pasaría siempre aunque
    // hubiera fugas. Esto verifica que siguen funcionando.
    expect(patronToString.hasMatch('return Error(e.toString());'), isTrue);
    expect(patronToString.hasMatch('return Error<bool>(e.toString());'), isTrue);
    expect(
      patronToString.hasMatch('return Error<List<Notificacion>>(e.toString());'),
      isTrue,
    );
    expect(patronInterpolacion.hasMatch("errorMessage: 'Error inesperado: \$e',"), isTrue);
    expect(patronInterpolacion.hasMatch('return Error("fallo \${e}");'), isTrue);

    // Y que no marcan como fuga el uso correcto.
    expect(patronToString.hasMatch('return Error(mensajeErrorRed(e));'), isFalse);
    expect(patronInterpolacion.hasMatch('return Error(mensajeErrorRed(e));'), isFalse);
    expect(patronToString.hasMatch("{'page': page.toString()},"), isFalse);
    // Un identificador que empieza por "e" no es la excepción.
    expect(patronInterpolacion.hasMatch("Text('Hola \$estudiante')"), isFalse);

    // Las líneas de log sí pueden llevar el detalle técnico, incluidas las
    // continuaciones de una llamada que ocupa varias líneas.
    final marcas = lineasDeLog([
      "AppLogger.error('fallo: \$e', tag: 'X');", // log de una línea
      "errorMessage: 'fallo: \$e',", // fuga real
      'AppLogger.error(', // log multilínea: apertura
      "    'fallo: \$e',", //   continuación
      "    tag: 'X');", //   cierre
      "errorMessage: 'otra fuga: \$e',", // fuga tras cerrar el log
    ]);
    expect(marcas, [true, false, true, true, true, false]);
  });
}
