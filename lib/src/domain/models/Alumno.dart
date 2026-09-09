import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';

/// Un alumno de la familia, con los pagos que le corresponden.
///
/// **Solo lleva los campos que la app pinta o usa.** El 2026-09-09 el backend
/// dejó de mandar `familia_id`, `ap_paterno`, `ap_materno`, las cuatro becas y
/// `grupo_id`: ninguno se mostraba en pantalla y se repetían en cada alumno de
/// cada respuesta. No volver a añadirlos «por si acaso» —el peso de la
/// respuesta es lo que se estaba recortando—; si algún día hace falta uno, se
/// pide al backend y se da de alta aquí a la vez.
class Alumno {
  int alumnoId;
  String familia;
  String alumno;
  String nombre;
  bool esBaja;
  String grupo;
  String urlPhoto;
  List<EstadoDeCuenta> estadoDeCuenta;

  Alumno({
    required this.alumnoId,
    required this.familia,
    required this.alumno,
    required this.nombre,
    required this.esBaja,
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
    familia: familia,
    alumno: alumno,
    nombre: nombre,
    esBaja: esBaja,
    grupo: grupo,
    urlPhoto: urlPhoto,
    estadoDeCuenta: pagos,
  );

  factory Alumno.fromJson(Map<String, dynamic> json) => Alumno(
    alumnoId: json['alumno_id'] ?? 0,
    familia: json['familia']?.toString() ?? '',
    alumno: json['alumno']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    esBaja: json['es_baja'] ?? false,
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
    'familia': familia,
    'alumno': alumno,
    'nombre': nombre,
    'es_baja': esBaja,
    'grupo': grupo,
    'url_photo': urlPhoto,
    'estado_de_cuenta': List<dynamic>.from(
      estadoDeCuenta.map((x) => x.toJson()),
    ),
  };
}
