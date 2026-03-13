import 'dart:convert';

import 'package:arjipagos/src/domain/models/Alumno.dart';

EstatodosDeCuentaResponse estatodosDeCuentaResponseFromJson(String str) => EstatodosDeCuentaResponse.fromJson(json.decode(str));

String estatodosDeCuentaResponseToJson(EstatodosDeCuentaResponse data) => json.encode(data.toJson());

class EstatodosDeCuentaResponse {
    String cicloPredeterminadoId;
    String familiaId;
    String familia;
    List<Alumno> alumnos;

    EstatodosDeCuentaResponse({
        required this.cicloPredeterminadoId,
        required this.familiaId,
        required this.familia,
        required this.alumnos,
    });

    factory EstatodosDeCuentaResponse.fromJson(Map<String, dynamic> json) => EstatodosDeCuentaResponse(
        cicloPredeterminadoId: json['ciclo_predeterminado_id'].toString(),
        familiaId: json['familia_id'].toString(),
        familia: json['familia'],
        alumnos: List<Alumno>.from(json['alumnos'].map((x) => Alumno.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        'ciclo_predeterminado_id': cicloPredeterminadoId,
        'familia_id': familiaId,
        'familia': familia,
        'alumnos': List<dynamic>.from(alumnos.map((x) => x.toJson())),
    };
}
