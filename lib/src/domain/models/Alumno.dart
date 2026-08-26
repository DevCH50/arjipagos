import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';

class Alumno {
  int alumnoId;
  int familiaId;
  String familia;
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
    required this.familiaId,
    required this.familia,
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

  /// El mismo alumno pero con otra lista de pagos.
  ///
  /// Lo usan las pantallas que muestran un subconjunto —hoy, los pagos de un
  /// solo emisor fiscal— para no repintar con la lista completa ni tener que
  /// mutar el modelo que vino del servidor.
  Alumno conEstadoDeCuenta(List<EstadoDeCuenta> pagos) => Alumno(
    alumnoId: alumnoId,
    familiaId: familiaId,
    familia: familia,
    alumno: alumno,
    apPaterno: apPaterno,
    apMaterno: apMaterno,
    nombre: nombre,
    becaSep: becaSep,
    becaArji: becaArji,
    becaBach: becaBach,
    becaSp: becaSp,
    esBaja: esBaja,
    grupoId: grupoId,
    grupo: grupo,
    urlPhoto: urlPhoto,
    estadoDeCuenta: pagos,
  );

  factory Alumno.fromJson(Map<String, dynamic> json) => Alumno(
    alumnoId: json['alumno_id'] ?? 0,
    familiaId: json['familia_id'] ?? 0,
    familia: json['familia']?.toString() ?? '',
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
    'familia_id': familiaId,
    'familia': familia,
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
