import 'package:arjipagos/src/core/utils/uuid_v4.dart';
import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';

/// Identificador estable de este teléfono, para el registro de FCM.
///
/// ## Qué problema resuelve
///
/// Hasta el 2026-09-17 el backend guardaba una fila por **token** de FCM, y el
/// token es cualquier cosa menos estable: Firebase lo rota al reinstalar, al
/// borrar los datos de la app, al actualizar Play Services o al restaurar el
/// aparato. Cada rotación creaba una fila nueva que **no se distinguía de un
/// segundo teléfono real**, así que al usuario le quedaban tokens de sobra que
/// Firebase seguía dando por vivos: 27 en total, 11 de un solo usuario.
///
/// Con un identificador propio que no cambia, el registro puede **actualizar**
/// la fila en vez de crear otra.
///
/// ## Por qué va en [SecureStorage] y NO en `SharedPref`
///
/// `AuthRepositoryImpl.logout()` termina con `sharedPref.clear()`. Un id
/// guardado ahí se borraría **en cada cierre de sesión**, que es justo el
/// momento en que el siguiente login lo necesita para reconocer el teléfono. El
/// resultado sería el problema de siempre —una fila nueva por login— pero ya
/// con el código puesto y la sensación de estar arreglado. Sería un fallo
/// silencioso, sin crash.
///
/// `SecureStorage.clearUserSession()` solo toca `user_session`, `access_token`
/// y `refresh_token`, y `deleteAll()` no se usa en ninguna parte de `lib/`: la
/// clave de este archivo es propia y **sobrevive al logout a propósito**.
///
/// Hay un test guardián —`test/unit/dispositivo_id_no_en_sharedpref_test.dart`—
/// que falla si alguien mueve esto a `SharedPref`.
///
/// Mismo razonamiento que en `BiometriaStorage`, que es el precedente.
class DispositivoStorage {
  final SecureStorage secureStorage;

  DispositivoStorage(this.secureStorage);

  /// Clave del identificador. Propia, fuera de las de sesión.
  static const String claveDeviceId = 'dispositivo_device_id';

  /// Devuelve el identificador de este teléfono, creándolo la primera vez.
  ///
  /// **Nunca regenera uno existente**: en eso consiste todo. Solo se genera si
  /// no hay nada guardado, o si lo guardado está vacío —que no debería pasar,
  /// pero un valor vacío no serviría de clave y es mejor rehacerlo que mandar
  /// una cadena en blanco al backend—.
  Future<String> obtenerDeviceId() async {
    final String? guardado = await secureStorage.read(claveDeviceId);
    if (guardado != null && guardado.isNotEmpty) {
      return guardado;
    }

    final String nuevo = generarUuidV4();
    await secureStorage.write(claveDeviceId, nuevo);
    return nuevo;
  }
}
