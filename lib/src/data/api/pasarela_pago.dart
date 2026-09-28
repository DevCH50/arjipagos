/// Pasarela por la que cobra cada emisor fiscal.
///
/// Un emisor fiscal es un contrato distinto, con su propia cuenta bancaria, y
/// desde el 2026-09-24 **ni siquiera comparten proveedor**: el emisor 1 cobra
/// por Adquira y el 2 por OpenPay. Esta enumeración es lo que separa los dos
/// caminos, y vive en su propio archivo para que añadir una pasarela nueva no
/// obligue a tocar la configuración de las que ya funcionan.
///
/// Lo que cambia de una a otra es **cómo se consigue la URL que abre el
/// WebView**; a partir de ahí la pantalla de pago es la misma, porque las dos
/// terminan en un retorno del backend que responde `{success, message}`.
library;

/// Proveedor con el que se cobra un emisor fiscal.
enum PasarelaPago {
  /// Adquira México. La app hace un **POST con formulario** directamente al
  /// endpoint del comercio, con los parámetros del contrato (`idexpress`,
  /// `mediospago`…) que lleva [ConfiguracionAdquira].
  ///
  /// Es como ha funcionado la app desde siempre. **No se toca.**
  adquira,

  /// OpenPay, en su modalidad «Botón de pago».
  ///
  /// La app **no habla con OpenPay**: le pide la URL del formulario alojado al
  /// backend (`/api/v1/openpay/crear-cargo`) y abre esa URL con un **GET**.
  ///
  /// El motivo de no llamar a OpenPay desde aquí es que crear el cobro
  /// (`POST /v1/{merchant}/checkouts`) exige la **llave privada** `sk_…`, y una
  /// llave privada dentro del APK se extrae con `unzip` y `strings`: con ella
  /// se pueden crear cargos y hacer devoluciones en el comercio. Por eso la
  /// guarda el servidor.
  openpay,
}
