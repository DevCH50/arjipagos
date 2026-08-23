/// Estado persistido de las invitaciones a calificar la app.
///
/// Es lo único que hace falta para decidir si toca volver a invitar al usuario.
/// Vive en el dominio porque la política de cuándo invitar es una regla de
/// negocio, no un detalle de almacenamiento.
class EstadoResena {
  /// Primera vez que la app registró actividad del usuario.
  ///
  /// Es `null` mientras no se haya registrado ningún pago exitoso: no se
  /// invita a calificar a alguien que todavía no ha usado la app.
  final DateTime? primerUso;

  /// Pagos completados con éxito acumulados desde la instalación.
  final int pagosExitosos;

  /// Última vez que se pidió la reseña, o `null` si nunca se ha pedido.
  final DateTime? ultimaInvitacion;

  /// Cuántas veces se ha pedido en los últimos 365 días.
  final int invitacionesUltimoAnio;

  const EstadoResena({
    this.primerUso,
    this.pagosExitosos = 0,
    this.ultimaInvitacion,
    this.invitacionesUltimoAnio = 0,
  });

  /// Estado de un usuario que aún no ha hecho nada.
  static const EstadoResena vacio = EstadoResena();

  @override
  String toString() =>
      'EstadoResena(primerUso: $primerUso, pagosExitosos: $pagosExitosos, '
      'ultimaInvitacion: $ultimaInvitacion, '
      'invitacionesUltimoAnio: $invitacionesUltimoAnio)';
}
