import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';

/// Persistencia de la preferencia del bloqueo biométrico.
///
/// ## Por qué va en [SecureStorage] y NO en `SharedPref`
///
/// `AuthRepositoryImpl.logout()` termina con `sharedPref.clear()`. Cualquier
/// preferencia guardada ahí **se destruye al cerrar sesión**. Para el cerrojo
/// eso ya sería molesto —el usuario tendría que volver a activarlo cada vez—,
/// y cuando se añada el login biométrico sería directamente fatal: el secreto
/// que sirve para volver a entrar se borraría justo en el momento en que hace
/// falta.
///
/// `SecureStorage.clearUserSession()` solo toca `user_session`, `access_token`
/// y `refresh_token`. Las claves de este archivo son propias y sobreviven al
/// cierre de sesión a propósito.
///
/// Hay un test guardián —`test/unit/biometria_no_en_sharedpref_test.dart`— que
/// falla si alguien mueve esto a `SharedPref`.
class BiometriaStorage {
  final SecureStorage secureStorage;

  BiometriaStorage(this.secureStorage);

  /// Clave de la preferencia del cerrojo. Propia, fuera de las de sesión.
  static const String claveBloqueoActivado = 'biometria_bloqueo_activado';

  static const String _si = '1';

  /// Si el usuario activó el bloqueo al abrir la app.
  ///
  /// Ante un valor corrupto o ausente devuelve `false`: la función es opcional
  /// y lo seguro por omisión es no dejar a nadie fuera de su propia app.
  Future<bool> bloqueoActivado() async {
    final String? valor = await secureStorage.read(claveBloqueoActivado);
    return valor == _si;
  }

  /// Guarda la preferencia.
  Future<void> guardarBloqueoActivado(bool activado) async {
    if (activado) {
      await secureStorage.write(claveBloqueoActivado, _si);
    } else {
      // Se borra en vez de escribir '0': deja el almacén sin residuos y hace
      // que "no hay clave" y "está apagado" sean el mismo estado.
      await secureStorage.delete(claveBloqueoActivado);
    }
  }
}
