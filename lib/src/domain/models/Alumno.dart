import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';

class Alumno {
  int alumnoId;
  String alumno;
  String apPaterno;
  String apMaterno;
  String nombre;
  String becaSep;
  String becaArji;
  String becaBach;
  String becaSp;
  bool esBaja;
  int grupoId;
  String grupo;
  String urlPhoto;
  List<EstadoDeCuenta> estadoDeCuenta;

  Alumno({
    required this.alumnoId,
    required this.alumno,
    required this.apPaterno,
    required this.apMaterno,
    required this.nombre,
    required this.becaSep,
    required this.becaArji,
    required this.becaBach,
    required this.becaSp,
    required this.esBaja,
    required this.grupoId,
    required this.grupo,
    required this.urlPhoto,
    required this.estadoDeCuenta,
  });

  factory Alumno.fromJson(Map<String, dynamic> json) => Alumno(
    alumnoId: json['alumno_id'] ?? 0,
    alumno: json['alumno']?.toString() ?? '',
    apPaterno: json['ap_paterno']?.toString() ?? '',
    apMaterno: json['ap_materno']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    becaSep: json['beca_sep']?.toString() ?? '',
    becaArji: json['beca_arji']?.toString() ?? '',
    becaBach: json['beca_bach']?.toString() ?? '',
    becaSp: json['beca_sp']?.toString() ?? '',
    esBaja: json['es_baja'] ?? false,
    grupoId: json['grupo_id'] ?? 0,
    grupo: json['grupo']?.toString() ?? '',
    urlPhoto: json['url_photo']?.toString() ?? '',
    estadoDeCuenta: json['estado_de_cuenta'] != null
        ? List<EstadoDeCuenta>.from(
            json['estado_de_cuenta'].map((x) => EstadoDeCuenta.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    'alumno_id': alumnoId,
    'alumno': alumno,
    'ap_paterno': apPaterno,
    'ap_materno': apMaterno,
    'nombre': nombre, 
    'beca_sep': becaSep,
    'beca_arji': becaArji,
    'beca_bach': becaBach,
    'beca_sp': becaSp,
    'es_baja': esBaja,
    'grupo_id': grupoId,
    'grupo': grupo,
    'url_photo': urlPhoto,
    'estado_de_cuenta': List<dynamic>.from(
      estadoDeCuenta.map((x) => x.toJson()),
    ),
  };
}
