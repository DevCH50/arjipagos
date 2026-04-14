import 'dart:convert';

import 'package:arjipagos/src/domain/models/Alumno.dart';

EstadosDeCuentaResponse estadosDeCuentaResponseFromJson(String str) => EstadosDeCuentaResponse.fromJson(json.decode(str));

String estadosDeCuentaResponseToJson(EstadosDeCuentaResponse data) => json.encode(data.toJson());

class EstadosDeCuentaResponse {
    String cicloPredeterminadoId;
    String familiaId;
    String familia;
    List<Alumno> alumnos;
    bool success;
    String message;

    EstadosDeCuentaResponse({ 
        required this.cicloPredeterminadoId,
        required this.familiaId,
        required this.familia,
        required this.alumnos,
        required this.success,
        required this.message,
    });

    factory EstadosDeCuentaResponse.fromJson(Map<String, dynamic> json) => EstadosDeCuentaResponse(
        cicloPredeterminadoId: json['ciclo_predeterminado_id'].toString(),
        familiaId: json['familia_id'].toString(),
        familia: json['familia'],
        alumnos: List<Alumno>.from(json['alumnos'].map((x) => Alumno.fromJson(x))),
        success: json['success'],
        message: json['message'],
    );

    Map<String, dynamic> toJson() => {
        'ciclo_predeterminado_id': cicloPredeterminadoId,
        'familia_id': familiaId,
        'familia': familia,
        'alumnos': List<dynamic>.from(alumnos.map((x) => x.toJson())),
        'success': success,
        'message': message,
    };
}
