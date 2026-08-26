/// Qué tipo de desbloqueo admite el aparato en el que corre la app.
///
/// Se consulta una sola vez al arrancar el [BiometriaBloc] y decide dos cosas:
/// si se ofrece el interruptor del bloqueo, y con qué icono y con qué palabras
/// se le habla al usuario. **No** llamamos "Face ID" a un lector de huellas
/// Android ni "huella" a un reconocimiento facial.
enum BiometriaDisponible {
  /// El aparato no admite biometría ni tiene bloqueo de pantalla configurado.
  /// El interruptor se muestra deshabilitado, con la razón escrita.
  ninguna,

  /// Reconocimiento facial. En iOS es Face ID; en Android, el desbloqueo facial
  /// del fabricante.
  rostro,

  /// Lector de huella. En iOS es Touch ID.
  huella,

  /// Android reporta un sensor biométrico "fuerte" o "débil" sin decir de qué
  /// tipo es — el caso más común en Android, de hecho.
  ///
  /// Con esto no se puede prometer al usuario ni cara ni huella, así que se le
  /// habla en genérico ("desbloqueo biométrico"). Cualquier otra cosa sería
  /// mentirle a la mitad de los aparatos.
  generica,

  /// No hay biometría dada de alta, pero sí un PIN, patrón o código de acceso.
  ///
  /// Sigue sirviendo para el cerrojo: `biometricOnly: false` deja que el sistema
  /// pida la credencial del dispositivo. Es lo que cubre a quien no quiere
  /// registrar su huella.
  soloCredencial,
}
