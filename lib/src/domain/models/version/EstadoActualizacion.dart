/// Qué debe hacer la app tras comparar su versión con la que publica el backend.
enum EstadoActualizacion {
  /// La versión instalada está al día: no se muestra nada.
  ninguna,

  /// Hay una versión más nueva, pero la instalada sigue siendo válida.
  /// El diálogo se puede descartar con "Ahora no".
  sugerida,

  /// La versión instalada quedó por debajo del mínimo: hay que actualizar.
  /// El diálogo no se puede descartar.
  obligatoria,

  /// El backend está en mantenimiento: se bloquea sin ofrecer la tienda.
  mantenimiento,
}

/// Veredicto listo para pintar: el estado, el texto que verá el usuario y el
/// enlace de tienda ya resuelto.
///
/// El diálogo no tiene que decidir nada: no consulta la plataforma ni elige
/// mensajes de respaldo, solo muestra lo que trae este objeto.
class ResultadoActualizacion {
  final EstadoActualizacion estado;

  /// Mensaje para el usuario. Es el del backend si lo mandó; si no, el de
  /// respaldo que corresponde al [estado].
  final String mensaje;

  /// Ficha de la tienda de esta plataforma, ya resuelta (backend o respaldo
  /// local). Puede quedar vacía, y entonces no se ofrece el botón.
  final String urlTienda;

  const ResultadoActualizacion({
    required this.estado,
    this.mensaje = '',
    this.urlTienda = '',
  });

  /// Veredicto neutro: se usa cuando la consulta falla o no hay nada que hacer.
  static const ResultadoActualizacion sinCambios = ResultadoActualizacion(
    estado: EstadoActualizacion.ninguna,
  );

  /// `true` si el usuario no puede seguir usando la app sin actuar.
  bool get bloquea =>
      estado == EstadoActualizacion.obligatoria ||
      estado == EstadoActualizacion.mantenimiento;

  /// `true` si hay algo que mostrarle al usuario.
  bool get requiereDialogo => estado != EstadoActualizacion.ninguna;
}
