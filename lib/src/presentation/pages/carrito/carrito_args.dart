/// Argumentos de la ruta `carrito`.
///
/// Solo lleva el emisor fiscal, y es lo único que necesita: la selección de
/// pagos vive en `SeleccionPagosStorage` y los datos de los alumnos los pide el
/// propio BLoC al entrar. Lo que el carrito no puede adivinar por su cuenta es
/// **cuál de los dos carritos** se está abriendo, porque la selección de ambos
/// emisores se guarda junta.
class CarritoArgs {
  /// Emisor fiscal cuyos pagos se van a ver y cobrar.
  final int emisorFiscalId;

  const CarritoArgs({required this.emisorFiscalId});
}
