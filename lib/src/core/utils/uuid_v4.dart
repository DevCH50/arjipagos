/// Generador de UUID versión 4 (aleatorio), según la RFC 4122.
///
/// ## Por qué propio y no un paquete
///
/// El proyecto solo necesita **un** identificador aleatorio, generado **una vez**
/// en la vida del dispositivo. Traer el paquete `uuid` para eso sería una
/// dependencia más que mantener, revisar en cada actualización y cargar en el
/// binario, a cambio de las quince líneas de abajo. Decisión de Carlos del
/// 2026-09-17, al montar el `device_id` estable.
///
/// ## Por qué `Random.secure()` y no `Random()`
///
/// `Random()` es un generador pseudoaleatorio sembrado con el reloj: dos
/// dispositivos que arrancasen la app en el mismo milisegundo podrían sacar el
/// mismo valor, y dos ids iguales significarían dos teléfonos peleándose por la
/// misma fila en el backend. `Random.secure()` usa la fuente de entropía del
/// sistema operativo y no tiene ese problema.
library;

import 'dart:math';

/// Cuántos bytes tiene un UUID.
const int _kBytesUuid = 16;

/// Genera un UUID v4 canónico, en minúsculas y con los guiones en su sitio
/// (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`).
///
/// De los 128 bits, seis están fijados por la norma —cuatro de versión y dos de
/// variante—, así que quedan 122 bits aleatorios. La probabilidad de que dos
/// llamadas devuelvan lo mismo es despreciable.
String generarUuidV4() {
  final Random azar = Random.secure();
  final List<int> bytes = List<int>.generate(
    _kBytesUuid,
    (_) => azar.nextInt(256),
  );

  // Byte 6, nibble alto = 4. Es lo que marca «versión 4, aleatorio».
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Byte 8, dos bits altos = 10. Es la variante RFC 4122; hace que el dígito
  // decimoséptimo del texto sea siempre 8, 9, a o b.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final String hex = bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
