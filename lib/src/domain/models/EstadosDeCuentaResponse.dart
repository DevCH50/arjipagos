import 'dart:convert';

import 'package:arjipagos/src/domain/models/Alumno.dart';

EstadosDeCuentaResponse estadosDeCuentaResponseFromJson(String str) =>
    EstadosDeCuentaResponse.fromJson(json.decode(str));

String estadosDeCuentaResponseToJson(EstadosDeCuentaResponse data) =>
    json.encode(data.toJson());

class EstadosDeCuentaResponse {
  String familia;
  List<Alumno> alumnos;
  bool success;
  String message;

  EstadosDeCuentaResponse({
    required this.familia,
    required this.alumnos,
    required this.success,
    required this.message,
  });

  /// Respuesta sin alumnos ni familia, para cuando el usuario no tiene nada
  /// que mostrar.
  ///
  /// El backend contesta ese caso con un `404` en vez de con una lista vacía
  /// (ver `esRespuestaSinDatos`), así que el service necesita fabricar aquí el
  /// vacío. Con `success: true` porque la consulta fue bien: sencillamente no
  /// hay estados de cuenta, que no es lo mismo que un fallo.
  factory EstadosDeCuentaResponse.vacio() => EstadosDeCuentaResponse(
    familia: '',
    alumnos: <Alumno>[],
    success: true,
    message: '',
  );

  factory EstadosDeCuentaResponse.fromJson(Map<String, dynamic> json) =>
      EstadosDeCuentaResponse(
        familia: json['familia'],
        alumnos: List<Alumno>.from(
          json['alumnos'].map((x) => Alumno.fromJson(x)),
        ),
        success: json['success'],
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {
    'familia': familia,
    'alumnos': List<dynamic>.from(alumnos.map((x) => x.toJson())),
    'success': success,
    'message': message,
  };
}
