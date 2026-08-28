import 'dart:convert';

import 'package:arjipagos/src/domain/models/Alumno.dart';

AlumnoResponse AlumnoResponseFromJson(String str) =>
    AlumnoResponse.fromJson(json.decode(str));

String AlumnoResponseToJson(AlumnoResponse data) => json.encode(data.toJson());

class AlumnoResponse {
  int familiaId;
  String familia;
  int roleId;
  int cicloPredeterminadoId;
  String cicloPredeterminado;
  List<Alumno> alumnos;

  AlumnoResponse({
    required this.familiaId,
    required this.familia,
    required this.roleId,
    required this.cicloPredeterminadoId,
    required this.cicloPredeterminado,
    required this.alumnos,
  });

  /// Respuesta sin alumnos, para cuando el usuario no tiene ninguno asignado.
  ///
  /// El backend contesta ese caso con un `404` en vez de con una lista vacía
  /// (ver `esRespuestaSinDatos`), así que el vacío se fabrica aquí y la pantalla
  /// cae en su estado «No hay Alumnos registrados» en lugar de «Error al
  /// cargar».
  factory AlumnoResponse.vacio() => AlumnoResponse(
    familiaId: 0,
    familia: '',
    roleId: 0,
    cicloPredeterminadoId: 0,
    cicloPredeterminado: '',
    alumnos: <Alumno>[],
  );

  factory AlumnoResponse.fromJson(Map<String, dynamic> json) => AlumnoResponse(
    familiaId: json['familia_id'],
    familia: json['familia'],
    roleId: json['role_id'],
    cicloPredeterminadoId: json['ciclo_predeterminado_id'],
    cicloPredeterminado: json['ciclo_predeterminado'],
    alumnos: List<Alumno>.from(json['alumnos'].map((x) => Alumno.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    'familia_id': familiaId,
    'familia': familia,
    'role_id': roleId,
    'ciclo_predeterminado_id': cicloPredeterminadoId,
    'ciclo_predeterminado': cicloPredeterminado,
    'alumnos': List<dynamic>.from(alumnos.map((x) => x.toJson())),
  };
}
