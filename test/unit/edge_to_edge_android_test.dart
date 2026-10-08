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
}
