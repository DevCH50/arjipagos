/// En qué quedó un cobro de OpenPay, según `GET /api/v1/openpay/estado`.
///
/// Se pregunta al cerrar el WebView de «Otros pagos» cuando no llegó el
/// retorno: OpenPay no vuelve solo a la app, y un tutor que cierra con la ✕
/// después de pagar no vería nunca el resultado.
library;

/// Los estados que distingue la app.
///
/// El backend manda cinco; la app reduce `sin_verificar` y `sin_aplicar` a
/// uno solo, [sinConfirmar], porque para el tutor significan lo mismo: puede
/// que el dinero sí saliera, y **no debe volver a pagar**.
enum EstadoCobro {
  /// El cobro entró y los cargos quedaron pagados.
  pagado,

  /// OpenPay o el banco lo rechazaron. No hubo cargo.
  rechazado,

  /// No hay cargo completado: el tutor cerró sin pagar, o OpenPay aún no lo
  /// marca. Quien llama reintenta un par de veces antes de creérselo.
  pendiente,

  /// No se pudo saber. Puede que se cobrara: **no volver a pagar**.
  ///
  /// Es también el estado de cualquier cosa que no se entienda —red caída,
  /// respuesta rota, un estado nuevo que esta versión no conoce—. Ante la
  /// duda, se elige lo que evita un pago doble.
  sinConfirmar,
}

/// Estado de un cobro y el mensaje que lo acompaña.
class EstadoCobroOpenpay {
  final EstadoCobro estado;

  /// El `message` del backend, tal cual. Puede venir vacío.
  ///
  /// Qué texto se le enseña al tutor lo decide la pantalla: usa éste cuando
  /// lo hay y uno propio cuando no.
  final String mensaje;

  /// `true` si no hubo respuesta que leer: la red falló, el servidor dio un
  /// 502 con su página HTML, o contestó algo que no es de este endpoint.
  ///
  /// Distingue ese «sin confirmar» del `sin_verificar` que manda el backend:
  /// el suyo es una respuesta de verdad y vale a la primera; éste es un
  /// parpadeo y merece otro intento. Visto en el Oppo el 2026-09-28: un 502
  /// suelto dejaba al tutor con «No pudimos confirmar tu pago» y el carrito
  /// vacío, cuando la consulta siguiente respondía con normalidad.
  final bool consultaFallida;

  const EstadoCobroOpenpay(this.estado, {this.mensaje = ''})
    : consultaFallida = false;

  /// Estado desconocido: no se pudo averiguar qué pasó con el cobro.
  const EstadoCobroOpenpay.sinConfirmar({
    this.mensaje = '',
    this.consultaFallida = false,
  }) : estado = EstadoCobro.sinConfirmar;

  /// Si conviene volver a preguntar antes de enseñarle nada al tutor.
  ///
  /// `pendiente` puede ser un cobro que OpenPay aún termina, y una consulta
  /// fallida no dice nada. El resto de estados son definitivos.
  bool get convieneReintentar =>
      estado == EstadoCobro.pendiente || consultaFallida;

  /// Construye el estado desde la respuesta del backend.
  ///
  /// Sin la clave `estado` no es una respuesta de este endpoint —Laravel
  /// contesta sus errores de framework con `{message}` y nada más—, así que
  /// se trata como [EstadoCobro.sinConfirmar] y **sin** ese mensaje, que está
  /// escrito para un programador.
  factory EstadoCobroOpenpay.desdeJson(Map<String, dynamic> json) {
    if (!json.containsKey('estado')) {
      return const EstadoCobroOpenpay.sinConfirmar(consultaFallida: true);
    }

    final String mensaje = (json['message'] ?? '').toString().trim();

    return EstadoCobroOpenpay(
      _estadoDesde(json['estado']?.toString() ?? ''),
      mensaje: mensaje,
    );
  }

  static EstadoCobro _estadoDesde(String valor) {
    return switch (valor.trim().toLowerCase()) {
      'pagado' => EstadoCobro.pagado,
      'rechazado' => EstadoCobro.rechazado,
      'pendiente' => EstadoCobro.pendiente,
      // `sin_verificar`, `sin_aplicar` y cualquier valor que llegue en el
      // futuro: sin certeza de que no se cobrara, lo prudente es no pagar.
      _ => EstadoCobro.sinConfirmar,
    };
  }
}
