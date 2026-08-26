/// Convierte a `int` un valor que puede llegar del backend como `int`, `num`
/// o `String` (p. ej. `2024` o `"2024"`).
///
/// El operador `??` por sí solo no basta: solo atrapa `null`, así que un
/// String asignado a un campo `int` reventaría el parseo del estado de cuenta
/// completo con un `TypeError`. El ciclo no llega tipado de forma confiable
/// (ver `EstadosDeCuentaResponse.fromJson`, que hace `.toString()`).
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
    /// Delimita el ámbito de las reglas de selección: el orden ascendente y el
    /// arrastre al deseleccionar se evalúan solo entre pagos del mismo ciclo.
    int cicloId;

    /// Nivel educativo del pago. Informativo: no interviene en la selección.
    int nivelId;

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

    String descripcionCorta;
    double total;
    String totalFormatted;
    String fechaVencimiento;
    EstadoPago estadoPago;
    int numPago;
    bool numPagoActivo;
    bool aceptaPagosDiversos;
    bool estaDisponibleEnInternet;
    bool estaDisponibleEnLaAppMovil;
    String facturaPdf;
    String facturaXml;

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
        required this.nivelId,
        required this.emisorFiscalId,
        required this.descripcionCorta,
        required this.total,
        required this.totalFormatted,
        required this.fechaVencimiento,
        required this.estadoPago,
        required this.numPago,
        required this.numPagoActivo,
        required this.aceptaPagosDiversos,
        required this.estaDisponibleEnInternet,
        required this.estaDisponibleEnLaAppMovil,
        required this.facturaPdf,
        required this.facturaXml,
        // Opcionales: solo existen en la respuesta de pagos realizados, así que
        // el flujo de pagos pendientes construye el modelo sin ellos.
        this.fechaDePago = '',
        this.ticketFolio = '',
        this.ticketUrl = '',
    });

    /// Indica si el pago tiene un ticket consultable.
    bool get tieneTicket => ticketUrl.isNotEmpty;

    /// Descripción con abreviaciones específicas por nivel/materia.
    String get descripcionAbreviada {
      const frases = {
        '1RO DE INGLES': '1º ING',
        'SEGURO ESCOLAR': 'SEG ESC',
        };
      const palabras = {
        'PRIMARIA': 'PRIM',
        'SECUNDARIA': 'SEC',
        'PREPARATORIA': 'PREPA',
        'PREESCOLAR': 'KIND',
        'COLEGIATURA': 'COL',
        'INSCRIPCION': 'INS',
        'REINSCRIPCION': 'REINS',
        'CUOTA FAMILIAR': 'CF',
      };

      var desc = descripcionCorta.toUpperCase();

      // Reemplazar frases completas primero
      for (final entry in frases.entries) {
        desc = desc.replaceAll(entry.key, entry.value);
      }

      // Reemplazar palabras individuales. El `where` no es cosmético: el
      // backend manda descripciones con espacios dobles y sobrantes al final
      // ('REINSCRIPCION SECUNDARIA  26 / 27  '), que en pantalla se comen ancho
      // y empujan el texto a una segunda línea sin necesidad.
      return desc
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => palabras[w] ?? w)
          .join(' ');
    }

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
        nivelId: _parseIntSeguro(json['nivel_id']),
        emisorFiscalId: _parseEmisorFiscal(json['emisorfiscal_id']),
        descripcionCorta: json['descripcion_corta']?.toString() ?? '',
        total: (json['total'] ?? 0).toDouble(),
        totalFormatted: json['total_formatted']?.toString() ?? '',
        fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
        estadoPago: estadoPagoValues.map[json['estadoPago']] ?? EstadoPago.pendiente,
        numPago: json['num_pago'] ?? 0,
        numPagoActivo: json['num_pago_activo'] ?? false,
        aceptaPagosDiversos: json['acepta_pagos_diversos'] ?? true,
        estaDisponibleEnInternet: json['esta_disponible_en_internet'] ?? true,
        estaDisponibleEnLaAppMovil: json['esta_disponible_en_la_app_movil'] ?? true,
        facturaPdf: json['factura_pdf']?.toString() ?? '',
        facturaXml: json['factura_xml']?.toString() ?? '',
        fechaDePago: json['fecha_de_pago']?.toString() ?? '',
        ticketFolio: json['ticket_folio']?.toString() ?? '',
        ticketUrl: json['ticket_url']?.toString() ?? '',
    );

    Map<String, dynamic> toJson() => {
        'id': id,
        'ciclo_id': cicloId,
        'nivel_id': nivelId,
        'emisorfiscal_id': emisorFiscalId,
        'descripcion_corta': descripcionCorta,
        'total': total,
        'total_formatted': totalFormatted,
        'fecha_vencimiento': fechaVencimiento,
        'estadoPago': estadoPagoValues.reverse[estadoPago],
        'num_pago': numPago,
        'num_pago_activo': numPagoActivo,
        'acepta_pagos_diversos': aceptaPagosDiversos,
        'esta_disponible_en_internet': estaDisponibleEnInternet,
        'esta_disponible_en_la_app_movil': estaDisponibleEnLaAppMovil,
        'factura_pdf': facturaPdf,
        'factura_xml': facturaXml,
        // Campos exclusivos de los pagos realizados. El endpoint de pagos
        // pendientes no los envía, así que solo se serializan cuando traen
        // valor: de lo contrario `fromJson`/`toJson` dejarían de ser inversas
        // para los pagos pendientes.
        if (fechaDePago.isNotEmpty) 'fecha_de_pago': fechaDePago,
        if (ticketFolio.isNotEmpty) 'ticket_folio': ticketFolio,
        if (ticketUrl.isNotEmpty) 'ticket_url': ticketUrl,
    };
}

enum EstadoPago {
    pendiente,
    vencido,
    pagado
}

final estadoPagoValues = EnumValues({
    'Pendiente': EstadoPago.pendiente,
    'Vencido': EstadoPago.vencido,
    'Pagado': EstadoPago.pagado
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
