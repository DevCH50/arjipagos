/// Convierte a `int` un valor que puede llegar del backend como `int`, `num`
/// o `String` (p. ej. `2024` o `"2024"`).
///
/// El operador `??` por sí solo no basta: solo atrapa `null`, así que un
/// String asignado a un campo `int` reventaría el parseo del estado de cuenta
/// completo con un `TypeError`. El ciclo no llega tipado de forma confiable:
/// unas respuestas lo mandan como número y otras como texto.
/// Emisor fiscal que se asume cuando el backend no manda `emisorfiscal_id`.
///
/// Vive en el dominio —y no en `ConfiguracionAdquira`, que lo reexporta— para
/// que la capa de datos dependa del dominio y no al revés.
///
/// Es 1 a propósito: antes de partir los pagos por emisor todo se cobraba con
/// la configuración del emisor 1, así que un backend que todavía no manda el
/// campo se sigue comportando exactamente igual que antes.
const int kEmisorFiscalPredeterminado = 1;

/// Lee `emisorfiscal_id` tolerando que el backend aún no lo mande.
///
/// No vale `_parseIntSeguro` a secas: devuelve `0` cuando falta la clave, y un
/// `0` no es ningún emisor real —dejaría el pago fuera de las dos pantallas y
/// sin forma de cobrarse—. Ausente o ilegible se traduce a
/// [kEmisorFiscalPredeterminado].
int _parseEmisorFiscal(dynamic valor) {
  if (valor == null) {
    return kEmisorFiscalPredeterminado;
  }
  final int emisor = _parseIntSeguro(valor);
  return emisor == 0 ? kEmisorFiscalPredeterminado : emisor;
}

int _parseIntSeguro(dynamic valor) {
  if (valor is int) {
    return valor;
  }
  if (valor is num) {
    return valor.toInt();
  }
  if (valor is String) {
    return int.tryParse(valor) ?? 0;
  }
  return 0;
}

class EstadoDeCuenta {
  int id;

  /// Ciclo escolar al que pertenece el pago.
  ///
  /// Es una de las cuatro piezas del ámbito de selección, junto con
  /// [emisorFiscalId], [pagoId] y [deudaAnterior]. Ver `AmbitoDeSeleccion`.
  int cicloId;

  /// Emisor fiscal que cobra este pago.
  ///
  /// Decide **dos cosas a la vez**: en qué pantalla aparece el renglón
  /// —"Pagos Pendientes" el 1, "Otros pagos" el 2— y con qué contrato de
  /// Adquira se cobra, porque cada emisor tiene su propio endpoint y su
  /// propia cuenta bancaria (ver `ConfiguracionAdquira`).
  ///
  /// De ahí que un carrito **nunca** pueda mezclar emisores: sería una sola
  /// transacción hacia dos cuentas distintas.
  int emisorFiscalId;

  /// Cargo del catálogo del que nace este renglón.
  ///
  /// Es **el concepto** a efectos de la selección: todas las parcialidades de
  /// un mismo cargo comparten `pago_id`, y es la clave con la que el propio
  /// backend las agrupa en parcialidades. Sin él, dos conceptos
  /// del mismo ciclo caían en una sola fila ordenada por id y el que tenía los
  /// ids más altos quedaba detrás de todo el otro: a IVANA no la dejaba pagar
  /// `EXTENSION DE HORARIO` sin liquidar antes `COLEGIATURA`.
  ///
  /// Llega desde el 08-sep-2026. Vale `0` con un backend que aún no lo mande,
  /// y entonces todos los pagos vuelven a caer en un solo ámbito: exactamente
  /// como se comportaba la app antes de tenerlo.
  ///
  /// El renglón trae además `concepto_id`, que **no se parsea a propósito**:
  /// cada `pago_id` pertenece a un solo concepto, así que en la clave del
  /// ámbito no distingue nada que `pagoId` no distinga ya, y aquí no se
  /// guardan campos que nadie usa.
  int pagoId;

  /// `true` si el cargo es el arrastre de un ciclo anterior.
  ///
  /// Va en el ámbito de selección junto a [pagoId]: una deuda vieja puede vivir
  /// en el ciclo en curso con el mismo cargo del catálogo que la deuda viva, y
  /// son dos filas de parcialidades independientes. El backend no las separa
  /// —agrupa solo por cargo y emisor—, así que si no entrara aquí, pagar la
  /// deuda anterior sería requisito para tocar el mes en curso.
  ///
  /// Llega desde el 08-sep-2026 en los dos endpoints, pendientes y pagados.
  bool deudaAnterior;

  String descripcionCorta;
  double total;
  String totalFormatted;
  String fechaVencimiento;
  EstadoPago estadoPago;
  int numPago;
  bool aceptaPagosDiversos;
  bool estaDisponibleEnInternet;

  /// Fecha y hora en que se liquidó el pago (`dd-MM-yyyy HH:mm:ss`).
  ///
  /// Solo llega en la respuesta de pagos realizados
  /// (`estado-de-cuenta-pagados`); en los pendientes queda vacía.
  String fechaDePago;

  /// Folio del ticket de pago (p. ej. `T7672`). Solo en pagos realizados.
  String ticketFolio;

  /// URL absoluta del ticket imprimible. Solo en pagos realizados.
  String ticketUrl;

  EstadoDeCuenta({
    required this.id,
    required this.cicloId,
    required this.emisorFiscalId,
    required this.descripcionCorta,
    required this.total,
    required this.totalFormatted,
    required this.fechaVencimiento,
    required this.estadoPago,
    required this.numPago,
    required this.aceptaPagosDiversos,
    required this.estaDisponibleEnInternet,
    // Opcionales con valor por defecto: el backend los añadió después, y con
    // uno que no los mande el ámbito de selección se colapsa al de antes.
    this.pagoId = 0,
    this.deudaAnterior = false,
    // Opcionales: solo existen en la respuesta de pagos realizados, así que
    // el flujo de pagos pendientes construye el modelo sin ellos.
    this.fechaDePago = '',
    this.ticketFolio = '',
    this.ticketUrl = '',
  });

  /// Indica si el pago tiene un ticket consultable.
  bool get tieneTicket => ticketUrl.isNotEmpty;

  /// Concepto del pago **completo**, tal como lo manda el backend.
  ///
  /// Hasta el 2026-08-28 este getter abreviaba: 'COLEGIATURA' salía como
  /// 'COL', 'SECUNDARIA' como 'SEC', 'CUOTA FAMILIAR' como 'CF'… La intención
  /// era que el concepto cupiera en una línea, pero el resultado era que el
  /// usuario leía un código en lugar de lo que está pagando. **Se muestra
  /// entero.** Que quepa es problema de la maquetación, no del dato: de eso se
  /// encarga `ConceptoPago`, que mantiene el tamaño y envuelve a las líneas
  /// que hagan falta — pero nunca corta.
  ///
  /// Lo único que se toca son los espacios: el backend manda descripciones con
  /// espacios dobles y sobrantes al final ('REINSCRIPCION SECUNDARIA  26 / 27  ')
  /// que en pantalla se comen ancho y empujan el texto a una segunda línea sin
  /// necesidad. Colapsarlos no quita información.
  ///
  /// Se conserva el `toUpperCase()` que ya había: no recorta nada y mantiene
  /// homogéneo el renglón, porque el backend no es constante con las mayúsculas.
  String get descripcionCompleta => descripcionCorta
      .toUpperCase()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .join(' ');

  /// Fecha de pago sin la hora, para las listas.
  ///
  /// El backend manda `fecha_de_pago` como '17-08-2026 10:01:01'. La hora no
  /// aporta nada en el listado y alarga la línea hasta recortarla con '...';
  /// el dato completo sigue disponible en [fechaDePago] y en el ticket.
  String get fechaDePagoCorta {
    if (fechaDePago.isEmpty) {
      return '';
    }
    return fechaDePago.split(' ').first;
  }

  factory EstadoDeCuenta.fromJson(Map<String, dynamic> json) => EstadoDeCuenta(
    id: _parseIntSeguro(json['id']),
    cicloId: _parseIntSeguro(json['ciclo_id']),
    emisorFiscalId: _parseEmisorFiscal(json['emisorfiscal_id']),
    // Ausente o ilegible cae en 0 / false, que es el ámbito único de siempre.
    pagoId: _parseIntSeguro(json['pago_id']),
    deudaAnterior: json['deuda_anterior'] == true,
    descripcionCorta: json['descripcion_corta']?.toString() ?? '',
    total: (json['total'] ?? 0).toDouble(),
    totalFormatted: json['total_formatted']?.toString() ?? '',
    fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
    estadoPago:
        estadoPagoValues.map[json['estadoPago']] ?? EstadoPago.pendiente,
    numPago: json['num_pago'] ?? 0,
    aceptaPagosDiversos: json['acepta_pagos_diversos'] ?? true,
    estaDisponibleEnInternet: json['esta_disponible_en_internet'] ?? true,
    fechaDePago: json['fecha_de_pago']?.toString() ?? '',
    ticketFolio: json['ticket_folio']?.toString() ?? '',
    ticketUrl: json['ticket_url']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ciclo_id': cicloId,
    'emisorfiscal_id': emisorFiscalId,
    // Solo lo manda el endpoint de pendientes: emitirlo siempre dejaría de ser
    // inverso de `fromJson` en el flujo de pagos realizados, igual que pasa con
    // los campos del ticket al revés.
    if (pagoId > 0) 'pago_id': pagoId,
    'descripcion_corta': descripcionCorta,
    'total': total,
    'total_formatted': totalFormatted,
    'fecha_vencimiento': fechaVencimiento,
    'estadoPago': estadoPagoValues.reverse[estadoPago],
    'num_pago': numPago,
    'acepta_pagos_diversos': aceptaPagosDiversos,
    'esta_disponible_en_internet': estaDisponibleEnInternet,
    // Campos exclusivos de los pagos realizados. El endpoint de pagos
    // pendientes no los envía, así que solo se serializan cuando traen
    // valor: de lo contrario `fromJson`/`toJson` dejarían de ser inversas
    // para los pagos pendientes.
    if (fechaDePago.isNotEmpty) 'fecha_de_pago': fechaDePago,
    if (ticketFolio.isNotEmpty) 'ticket_folio': ticketFolio,
    if (ticketUrl.isNotEmpty) 'ticket_url': ticketUrl,
    // Al final del renglón y sin condición, como lo mandan los dos endpoints.
    'deuda_anterior': deudaAnterior,
  };
}

enum EstadoPago { pendiente, vencido, pagado }

final estadoPagoValues = EnumValues({
  'Pendiente': EstadoPago.pendiente,
  'Vencido': EstadoPago.vencido,
  'Pagado': EstadoPago.pagado,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
