import 'dart:convert';

import 'package:arjipagos/src/domain/models/Factura.dart';

FacturaResponse facturaResponseFromJson(String str) =>
    FacturaResponse.fromJson(json.decode(str));

String facturaResponseToJson(FacturaResponse data) =>
    json.encode(data.toJson());

/// Respuesta del endpoint de facturas.
class FacturaResponse {
  int cicloPredeterminadoId;
  int familiaId;
  String familia;
  List<Factura> facturas;
  bool success;
  String message;

  FacturaResponse({
    required this.cicloPredeterminadoId,
    required this.familiaId,
    required this.familia,
    required this.facturas,
    required this.success,
    required this.message,
  });

  /// Respuesta sin facturas, para cuando el usuario no tiene ninguna.
  ///
  /// El backend contesta ese caso con un `404` en vez de con una lista vacía
  /// (ver `esRespuestaSinDatos`), así que el vacío se fabrica aquí. Con
  /// `success: true`: la consulta fue bien, sencillamente no hay facturas.
  factory FacturaResponse.vacio() => FacturaResponse(
    cicloPredeterminadoId: 0,
    familiaId: 0,
    familia: '',
    facturas: <Factura>[],
    success: true,
    message: '',
  );

  factory FacturaResponse.fromJson(Map<String, dynamic> json) =>
      FacturaResponse(
        cicloPredeterminadoId: json['ciclo_predeterminado_id'],
        familiaId: json['familia_id'],
        familia: json['familia'],
        facturas: List<Factura>.from(
          json['facturas'].map((x) => Factura.fromJson(x)),
        ),
        success: json['success'],
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {
    'ciclo_predeterminado_id': cicloPredeterminadoId,
    'familia_id': familiaId,
    'familia': familia,
    'facturas': List<dynamic>.from(facturas.map((x) => x.toJson())),
    'success': success,
    'message': message,
  };
}
