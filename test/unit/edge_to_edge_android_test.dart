/// Test guardián del edge-to-edge de Android 15 (SDK 35).
///
/// Origen: Play Console avisó «Es posible que la vista de extremo a extremo no
/// funcione para todos los usuarios» **tres veces**: en la 1.0.22 (build 31),
/// tras limpiar solo dos de los cuatro `styles.xml`; y en la 1.0.33 (build 42),
/// porque la app nunca llamaba a `enableEdgeToEdge()` nativo —el
/// `SystemChrome.setEnabledSystemUIMode` de Dart Play no lo ve—.
///
/// Cada vez se arregló a mano y nada impedía que volviera. Este test lo impide:
/// falla si se quita la llamada nativa, si la base de `MainActivity` deja de
/// admitirla, si `flutter_native_splash:create` (u otra cosa) vuelve a meter
/// `windowDrawsSystemBarBackgrounds` en cualquiera de los cuatro estilos, o si
/// desaparece el modo edge-to-edge de Dart.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _mainActivity =
    'android/app/src/main/kotlin/mx/moriah/arjipagos/MainActivity.kt';

/// Los CUATRO estilos: las variantes `-v31` mandan en Android 12+, y son las
/// que se olvidaron la primera vez.
const List<String> _estilos = [
  'android/app/src/main/res/values/styles.xml',
  'android/app/src/main/res/values-night/styles.xml',
  'android/app/src/main/res/values-v31/styles.xml',
  'android/app/src/main/res/values-night-v31/styles.xml',
];

/// Quita los comentarios de Kotlin y XML, para que una llamada comentada o
/// una explicación en un comentario no hagan pasar el test en falso.
String _sinComentarios(String fuente) => fuente
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');

/// Quita los comentarios (`#`) de las reglas de R8, para que una regla
/// comentada no haga pasar el test.
String _sinComentariosProguard(String reglas) =>
    reglas.replaceAll(RegExp(r'#[^\n]*'), '');

void main() {
  group('Edge-to-edge en Android 15', () {
    late String actividad;

    setUpAll(() {
      actividad = _sinComentarios(File(_mainActivity).readAsStringSync());
    });

    test('MainActivity llama a enableEdgeToEdge() nativo', () {
      expect(actividad, contains('import androidx.activity.enableEdgeToEdge'));
      expect(actividad, contains('enableEdgeToEdge()'));
    });

    test('la llamada va DESPUÉS de super.onCreate', () {
      // Dentro de super.onCreate Flutter pasa del tema del splash al normal;
      // tocar la ventana antes podría dejar ese cambio atrás.
      final int superOnCreate = actividad.indexOf('super.onCreate(');
      final int edgeToEdge = actividad.indexOf('enableEdgeToEdge()');

      expect(superOnCreate, isNonNegative);
      expect(edgeToEdge, greaterThan(superOnCreate));
    });

    test('la base desciende de ComponentActivity (FlutterFragmentActivity)', () {
      // Con `FlutterActivity` a secas enableEdgeToEdge() no existe: extiende
      // android.app.Activity. Volver a ella rompe la compilación y, con ella,
      // el arreglo de este aviso (y el BiometricPrompt).
      expect(actividad, contains(': FlutterFragmentActivity()'));
    });

    for (final String ruta in _estilos) {
      test('$ruta no lleva windowDrawsSystemBarBackgrounds', () {
        final String xml = _sinComentarios(File(ruta).readAsStringSync());

        expect(xml, isNot(contains('windowDrawsSystemBarBackgrounds')));
      });
    }

    test('main.dart mantiene el modo edge-to-edge de Dart', () {
      final String main = File('lib/main.dart').readAsStringSync();

      expect(main, contains('SystemUiMode.edgeToEdge'));
    });
  });

  // El segundo aviso de Play: «Tu aplicación usa APIs o parámetros obsoletos
  // para la vista de extremo a extremo» (`Window.setStatusBarColor` /
  // `setNavigationBarColor`, en `d.s.M`, `d.t.M`, `d.v.M`). Salió en la
  // 1.0.34+43, la primera con `enableEdgeToEdge()`: esas tres clases son las
  // ramas para Android < 15 del propio androidx.activity, ofuscadas por R8.
  group('APIs obsoletas de edge-to-edge (Android 15)', () {
    test('R8 no ofusca las clases EdgeToEdge de androidx.activity', () {
      final String reglas = _sinComentariosProguard(
        File('android/app/proguard-rules.pro').readAsStringSync(),
      );

      expect(
        reglas,
        contains('-keepnames class androidx.activity.EdgeToEdge* { *; }'),
      );
    });

    test('release.sh verifica el binario con verificar_edge_to_edge_dex.sh',
        () {
      // El test de arriba solo ve las reglas; lo que R8 produce de verdad lo
      // revisa ese script en el dex del APK/AAB. Que el release lo llame.
      final File script = File('scripts/verificar_edge_to_edge_dex.sh');
      final String release = File('scripts/release.sh')
          .readAsStringSync()
          .replaceAll(RegExp(r'#[^\n]*'), '');

      expect(script.existsSync(), isTrue);
      expect(release, contains('./scripts/verificar_edge_to_edge_dex.sh'));
    });

    test('el código nativo propio no llama a las APIs obsoletas', () {
      // Estas sí serían nuestras, con o sin ofuscar: Play las señalaría.
      final Iterable<File> fuentes = Directory('android/app/src/main')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt') || f.path.endsWith('.java'));

      expect(fuentes, isNotEmpty);
      for (final File fuente in fuentes) {
        final String codigo = _sinComentarios(fuente.readAsStringSync());

        expect(
          codigo,
          isNot(matches(RegExp(r'statusBarColor|navigationBarColor',
              caseSensitive: false))),
          reason: fuente.path,
        );
      }
    });
  });
}
