/// Modelo que representa una factura emitida.
///
/// El archivo ZIP se obtiene descargando [zipUrl] bajo demanda,
/// evitando transferir datos pesados en el listado inicial.
class Factura {
  int id;
  String folio;
  String fecha;
  String fechaTimbrado;
  String referencia;
  String total;
  String directorio;
  String pdf;
  String xml;

  /// URL de descarga del archivo ZIP (PDF + XML de la factura).
  String zipUrl;

  /// Nombre sugerido para el archivo ZIP al guardarlo o compartirlo.
  String zipNombre;

  Factura({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.fechaTimbrado,
    required this.referencia,
    required this.total,
    required this.directorio,
    required this.pdf,
    required this.xml,
    required this.zipUrl,
    required this.zipNombre,
  });

  factory Factura.fromJson(Map<String, dynamic> json) => Factura(
    id: json['id'],
    folio: json['folio'],
    fecha: json['fecha'],
    fechaTimbrado: json['fecha_timbrado'],
    referencia: json['referencia'],
    total: json['total'],
    directorio: json['directorio'],
    pdf: json['pdf'],
    xml: json['xml'],
    zipUrl: json['zip_url'],
    zipNombre: json['zip_nombre'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'folio': folio,
    'fecha': fecha,
    'fecha_timbrado': fechaTimbrado,
    'referencia': referencia,
    'total': total,
    'directorio': directorio,
    'pdf': pdf,
    'xml': xml,
    'zip_url': zipUrl,
    'zip_nombre': zipNombre,
  };
}
