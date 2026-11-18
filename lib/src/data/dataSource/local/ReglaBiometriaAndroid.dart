import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';

/// Primera versión de Android (API 30, Android 11) en la que el PIN del aparato
/// se pide **dentro** de `BiometricPrompt` y no con una pantalla aparte.
const int kSdkCredencialEnPrompt = 30;

/// Regla de plataforma del bloqueo biométrico en Android viejo.
///
/// ## Por qué existe
///
/// `local_auth_android` 2.3.0 usa androidx.biometric **1.1.0**. Por debajo de
/// Android 11 esa librería no puede pedir el PIN dentro de su diálogo: lanza la
/// pantalla del sistema (`ConfirmDeviceCredentialActivity`), y la lanza
/// **duplicada** —dos a la vez, y a veces una tercera al cerrar—. Comprobado en
/// el emulador de Android 7 el 2026-11-18: el usuario tenía que escribir el PIN
/// dos o tres veces seguidas. Dart solo pedía una vez; el fallo es nativo.
///
/// La salida: en esas versiones el cerrojo **solo se ofrece con biometría** y se
/// pide solo la huella (`biometricOnly`), que va por otra ruta de androidx que no
/// abre esa pantalla. Si el aparato solo tiene PIN, no se ofrece.
///
/// Son funciones puras, sin canal de plataforma, para poder probarlas.
/// [sdk] es `null` fuera de Android (iOS) o si no se pudo leer: entonces no se
/// toca nada, porque en iOS el problema no existe.
class ReglaBiometriaAndroid {
  const ReglaBiometriaAndroid._();

  /// Si en esta versión de Android hay que evitar la pantalla de PIN del sistema.
  static bool evitarCredencial(int? sdk) =>
      sdk != null && sdk < kSdkCredencialEnPrompt;

  /// Ajusta lo que el aparato admite a lo que el cerrojo puede usar sin fallar.
  static BiometriaDisponible ajustar(BiometriaDisponible disponible, int? sdk) {
    if (evitarCredencial(sdk) &&
        disponible == BiometriaDisponible.soloCredencial) {
      return BiometriaDisponible.ninguna;
    }
    return disponible;
  }
}
