/// Tests unitarios del comparador de versiones.
///
/// Es la pieza que decide si a un usuario se le bloquea la app, así que aquí se
/// blindan sobre todo los casos en los que **no** debe bloquear: sin umbrales,
/// con versiones iguales o con datos raros.
library;

import 'package:arjipagos/src/core/utils/version_comparador.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compararSemver', () {
    test('ordena versiones con el mismo número de partes', () {
      expect(compararSemver('1.0.24', '1.0.25'), lessThan(0));
      expect(compararSemver('1.0.25', '1.0.24'), greaterThan(0));
      expect(compararSemver('1.0.24', '1.0.24'), 0);
    });

    test('compara por peso, no alfabéticamente', () {
      // '9' > '10' si se comparara como texto.
      expect(compararSemver('1.0.9', '1.0.10'), lessThan(0));
      expect(compararSemver('2.0.0', '10.0.0'), lessThan(0));
    });

    test('rellena con ceros cuando faltan partes', () {
      expect(compararSemver('1.0', '1.0.0'), 0);
      expect(compararSemver('1.0', '1.0.1'), lessThan(0));
      expect(compararSemver('2', '1.9.9'), greaterThan(0));
    });

    test('ignora sufijos no numéricos', () {
      expect(compararSemver('1.0.25-beta', '1.0.25'), 0);
      expect(compararSemver('1.0.25+3', '1.0.24'), greaterThan(0));
    });

    test('trata como cero lo que no se puede interpretar', () {
      expect(compararSemver('', '0.0.0'), 0);
      expect(compararSemver('vieja', '1.0.0'), lessThan(0));
    });
  });

  group('requiereActualizacion', () {
    test('manda el build number cuando el backend lo envía', () {
      expect(
        requiereActualizacion(
          buildActual: 33,
          versionActual: '1.0.24',
          buildUmbral: 34,
        ),
        isTrue,
      );

      expect(
        requiereActualizacion(
          buildActual: 34,
          versionActual: '1.0.24',
          buildUmbral: 34,
        ),
        isFalse,
      );

      expect(
        requiereActualizacion(
          buildActual: 40,
          versionActual: '1.0.24',
          buildUmbral: 34,
        ),
        isFalse,
      );
    });

    test('el build tiene prioridad sobre el nombre de versión', () {
      // Aunque el nombre diga que está por debajo, el build manda.
      expect(
        requiereActualizacion(
          buildActual: 40,
          versionActual: '1.0.20',
          buildUmbral: 34,
          versionUmbral: '1.0.25',
        ),
        isFalse,
      );
    });

    test('cae al nombre de versión si no llega build mínimo', () {
      expect(
        requiereActualizacion(
          buildActual: 33,
          versionActual: '1.0.24',
          versionUmbral: '1.0.25',
        ),
        isTrue,
      );

      expect(
        requiereActualizacion(
          buildActual: 33,
          versionActual: '1.0.25',
          versionUmbral: '1.0.25',
        ),
        isFalse,
      );
    });

    test('sin umbrales no bloquea a nadie', () {
      expect(
        requiereActualizacion(buildActual: 1, versionActual: '0.0.1'),
        isFalse,
      );
    });

    test('un umbral vacío o en cero se ignora', () {
      expect(
        requiereActualizacion(
          buildActual: 1,
          versionActual: '0.0.1',
          buildUmbral: 0,
          versionUmbral: '   ',
        ),
        isFalse,
      );
    });
  });
}
