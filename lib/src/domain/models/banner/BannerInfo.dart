/// Formato en el que el backend manda el cuerpo de un banner.
///
/// Hoy siempre llega `markdown`, pero el campo `cuerpo_formato` existe
/// justamente para poder cambiarlo sin tocar la app.
enum BannerFormato {
  markdown,
  html,
  texto,
}

/// Banner informativo que se muestra en la tirilla del Menú Principal.
///
/// Es contenido tipo nota: una imagen de portada que al tocarse abre el cuerpo
/// completo. El cuerpo NO se interpreta aquí; el modelo solo lo transporta
/// junto con el formato en el que viene.
class BannerInfo {
  /// Identificador del banner en el backend.
  final int id;

  /// Encabezado de la nota.
  final String titulo;

  /// URL absoluta de la imagen de portada.
  final String imagenUrl;

  /// Fecha de publicación, ya formateada por el backend (`20-08-2026`).
  final String fecha;

  /// Cuerpo de la nota, en el formato que indica [formato].
  final String cuerpo;

  /// Formato del cuerpo.
  final BannerFormato formato;

  const BannerInfo({
    required this.id,
    required this.titulo,
    required this.imagenUrl,
    required this.fecha,
    required this.cuerpo,
    required this.formato,
  });

  /// Días durante los que un aviso se considera recién publicado.
  static const int diasReciente = 7;

  /// Un banner sin imagen no puede pintarse en la tirilla.
  bool get tieneImagen => imagenUrl.isNotEmpty;

  /// [fecha] convertida a `DateTime`, o `null` si no vino con el formato
  /// `dd-MM-yyyy` que manda el backend.
  ///
  /// Se parsea a mano en vez de con `DateTime.parse` porque ese espera
  /// `yyyy-MM-dd`: con `20-08-2026` lanzaría una excepción.
  DateTime? get fechaPublicacion {
    final partes = fecha.split('-');
    if (partes.length != 3) {
      return null;
    }

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);
    if (dia == null || mes == null || anio == null) {
      return null;
    }

    return DateTime(anio, mes, dia);
  }

  /// `true` durante los primeros [diasReciente] días desde la publicación.
  ///
  /// Sale de la fecha que ya manda el backend: no hace falta un campo nuevo
  /// para poder señalar los avisos recién puestos. Una fecha ilegible o futura
  /// no es reciente —mejor no marcar nada que marcar de más—.
  bool get esReciente {
    final publicacion = fechaPublicacion;
    if (publicacion == null) {
      return false;
    }

    final dias = DateTime.now().difference(publicacion).inDays;
    return dias >= 0 && dias <= diasReciente;
  }

  factory BannerInfo.fromJson(Map<String, dynamic> json) => BannerInfo(
        id: _parseIntSeguro(json['id']),
        titulo: json['titulo']?.toString() ?? '',
        imagenUrl: json['imagen_url']?.toString() ?? '',
        fecha: json['fecha']?.toString() ?? '',
        cuerpo: json['cuerpo']?.toString() ?? '',
        // Un formato desconocido cae a markdown, que es lo que manda el
        // backend hoy: mejor eso que dejar la nota en blanco.
        formato: _parseFormato(json['cuerpo_formato']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'imagen_url': imagenUrl,
        'fecha': fecha,
        'cuerpo': cuerpo,
        'cuerpo_formato': formato.name,
      };

  /// Convierte `cuerpo_formato` al enum, tolerando mayúsculas y valores nuevos.
  static BannerFormato _parseFormato(dynamic valor) {
    switch (valor?.toString().toLowerCase()) {
      case 'html':
        return BannerFormato.html;
      case 'texto':
      case 'text':
      case 'plain':
        return BannerFormato.texto;
      default:
        return BannerFormato.markdown;
    }
  }

  /// Convierte a int tolerando que el backend mande el id como texto.
  static int _parseIntSeguro(dynamic valor) {
    if (valor is int) {
      return valor;
    }
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
