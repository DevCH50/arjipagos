class EstadoDeCuenta {
    int id;
    String descripcionCorta;
    double total;
    String totalFormatted;
    String fechaVencimiento;
    EstadoPago estadoPago;
    int numPago;
    bool numPagoActivo;
    bool aceptaPagosDiversos;
    bool estaDisponibleEnInternet;
    String facturaPdf;
    String facturaXml;

    EstadoDeCuenta({
        required this.id,
        required this.descripcionCorta,
        required this.total,
        required this.totalFormatted,
        required this.fechaVencimiento,
        required this.estadoPago,
        required this.numPago,
        required this.numPagoActivo,
        required this.aceptaPagosDiversos,
        required this.estaDisponibleEnInternet,
        required this.facturaPdf,
        required this.facturaXml,
    });

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

      // Reemplazar palabras individuales
      return desc.split(' ').map((w) => palabras[w] ?? w).join(' ');
    }

    factory EstadoDeCuenta.fromJson(Map<String, dynamic> json) => EstadoDeCuenta(
        id: json['id'] ?? 0,
        descripcionCorta: json['descripcion_corta']?.toString() ?? '',
        total: (json['total'] ?? 0).toDouble(),
        totalFormatted: json['total_formatted']?.toString() ?? '',
        fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
        estadoPago: estadoPagoValues.map[json['estadoPago']] ?? EstadoPago.pendiente,
        numPago: json['num_pago'] ?? 0,
        numPagoActivo: json['num_pago_activo'] ?? false,
        aceptaPagosDiversos: json['acepta_pagos_diversos'] ?? true,
        estaDisponibleEnInternet: json['esta_disponible_en_internet'] ?? true,
        facturaPdf: json['factura_pdf']?.toString() ?? '',
        facturaXml: json['factura_xml']?.toString() ?? '',
    );

    Map<String, dynamic> toJson() => {
        'id': id,
        'descripcion_corta': descripcionCorta,
        'total': total,
        'total_formatted': totalFormatted,
        'fecha_vencimiento': fechaVencimiento,
        'estadoPago': estadoPagoValues.reverse[estadoPago],
        'num_pago': numPago,
        'num_pago_activo': numPagoActivo,
        'acepta_pagos_diversos': aceptaPagosDiversos,
        'esta_disponible_en_internet': estaDisponibleEnInternet,
        'factura_pdf': facturaPdf,
        'factura_xml': facturaXml,
    };
}

enum EstadoPago {
    pendiente,
    vencido
}

final estadoPagoValues = EnumValues({
    'Pendiente': EstadoPago.pendiente,
    'Vencido': EstadoPago.vencido
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
