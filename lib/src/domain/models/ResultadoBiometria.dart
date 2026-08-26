/// Desenlace de un intento de autenticación biométrica.
///
/// Se distinguen los casos porque **cada uno se le cuenta distinto al usuario**
/// y en algunos hay que apagar el bloqueo solo. Colapsarlos todos en un `bool`
/// dejaría al usuario encerrado sin saber por qué.
enum ResultadoBiometria {
  /// Identidad confirmada.
  exito,

  /// El usuario canceló, o falló y descartó el diálogo. No es un error: no se
  /// le muestra nada, simplemente sigue bloqueado con el botón de reintentar.
  cancelada,

  /// El aparato dejó de admitir biometría, o el usuario borró todas sus huellas
  /// desde que activó el bloqueo. Hay que **apagar el bloqueo solo**, o la
  /// persona se queda fuera de la app para siempre.
  noDisponible,

  /// Demasiados intentos fallidos. Android bloquea el sensor unos 30 segundos.
  /// Se reintenta más tarde; el bloqueo NO se apaga.
  bloqueoTemporal,

  /// Sensor bloqueado hasta que se desbloquee el aparato con PIN o patrón.
  /// Tampoco se apaga el bloqueo: se le dice que use su código.
  bloqueoPermanente,

  /// Cualquier otro fallo del canal nativo. Va al log con detalle; al usuario
  /// se le da la salida de "usar contraseña".
  error,
}
