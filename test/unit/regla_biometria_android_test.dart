import 'package:arjipagos/src/data/dataSource/local/ReglaBiometriaAndroid.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regla del cerrojo en Android viejo (ver `ReglaBiometriaAndroid.dart`).
///
/// Por debajo de Android 11, androidx.biometric 1.1.0 abre la pantalla de PIN
/// del sistema duplicada. Ahí el cerrojo solo se ofrece con biometría y se pide
/// solo la huella. En Android 11+ y en iOS no cambia nada.
void main() {
  group('evitarCredencial', () {
    test('Android 7 (24) a Android 10 (29): sí', () {
      for (final int sdk in <int>[24, 26, 28, 29]) {
        expect(ReglaBiometriaAndroid.evitarCredencial(sdk), isTrue,
            reason: 'SDK $sdk');
      }
    });

    test('Android 11 (30) en adelante: no', () {
      for (final int sdk in <int>[30, 34, 36, 37]) {
        expect(ReglaBiometriaAndroid.evitarCredencial(sdk), isFalse,
            reason: 'SDK $sdk');
      }
    });

    test('sin SDK (iOS o no se pudo leer): no', () {
      expect(ReglaBiometriaAndroid.evitarCredencial(null), isFalse);
    });
  });

  group('ajustar', () {
    test('Android viejo con solo PIN: no se ofrece el cerrojo', () {
      expect(
        ReglaBiometriaAndroid.ajustar(BiometriaDisponible.soloCredencial, 24),
        BiometriaDisponible.ninguna,
      );
    });

    test('Android viejo con biometría: se conserva', () {
      for (final BiometriaDisponible d in <BiometriaDisponible>[
        BiometriaDisponible.huella,
        BiometriaDisponible.rostro,
        BiometriaDisponible.generica,
      ]) {
        expect(ReglaBiometriaAndroid.ajustar(d, 28), d);
      }
    });

    test('Android 11+ e iOS: nada cambia, ni siquiera solo PIN', () {
      for (final BiometriaDisponible d in BiometriaDisponible.values) {
        expect(ReglaBiometriaAndroid.ajustar(d, 30), d);
        expect(ReglaBiometriaAndroid.ajustar(d, null), d);
      }
    });
  });
}
