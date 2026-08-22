/// Política de versión que publica el backend para esta plataforma.
///
/// Se obtiene de `GET /api/v1/app/version?plataforma=android|ios` y decide si
/// la app instalada debe actualizarse antes de poder seguir usándose.
///
/// **Todos los campos son opcionales.** El parseo es deliberadamente tolerante:
/// si el backend todavía no expone el endpoint, o devuelve un JSON incompleto,
/// el modelo queda con valores neutros y la app no bloquea a nadie. Bloquear a
/// un usuario por un fallo de red o por un despliegue a medias sería peor que
/// dejarlo con una versión vieja.
class VersionApp {
  /// Build number mínimo aceptado (el `+33` de `pubspec.yaml`).
  ///
  /// Es el criterio principal: un entero monotónico que Play Store y App Store
  /// obligan a incrementar en cada publicación, así que nunca es ambiguo.
  final int? buildMinimo;

  /// Build number a partir del cual la actualización solo se sugiere.
  final int? buildRecomendado;

  /// Nombre de versión mínimo (`1.0.25`). Respaldo si no viene [buildMinimo].
  final String? versionMinima;

  /// Nombre de versión recomendado. Respaldo si no viene [buildRecomendado].
  final String? versionRecomendada;

  /// Enlace a la ficha de la tienda que corresponde a esta plataforma.
  ///
  /// Lo manda el backend para poder corregirlo sin publicar un release nuevo.
  final String urlTienda;

  /// Texto que se muestra al usuario en el diálogo de actualización.
  final String mensaje;

  /// Interruptor de mantenimiento: bloquea la app sin ofrecer la tienda.
  final bool mantenimiento;

  /// Texto que se muestra durante el mantenimiento.
  final String mensajeMantenimiento;

  const VersionApp({
    this.buildMinimo,
    this.buildRecomendado,
    this.versionMinima,
    this.versionRecomendada,
    this.urlTienda = '',
    this.mensaje = '',
    this.mantenimiento = false,
    this.mensajeMantenimiento = '',
  });

  /// Modelo neutro: ni actualización ni mantenimiento.
  ///
  /// Es lo que se usa cuando la consulta falla, para que el resto del flujo
  /// pueda seguir sin ramas especiales.
  static const VersionApp vacia = VersionApp();

  /// Construye el modelo desde el JSON del backend.
  ///
  /// Ningún campo es obligatorio y los tipos se normalizan: un `"34"` en texto
  /// se acepta igual que un `34`, porque el backend puede serializar los
  /// enteros como cadenas según cómo se guarden en la base de datos.
  factory VersionApp.fromJson(Map<String, dynamic> json) {
    return VersionApp(
      buildMinimo: _comoEntero(json['build_minimo']),
      buildRecomendado: _comoEntero(json['build_recomendado']),
      versionMinima: _comoTextoONulo(json['version_minima']),
      versionRecomendada: _comoTextoONulo(json['version_recomendada']),
      urlTienda: _comoTexto(json['url_tienda']),
      mensaje: _comoTexto(json['mensaje']),
      mantenimiento: _comoBooleano(json['mantenimiento']),
      mensajeMantenimiento: _comoTexto(json['mensaje_mantenimiento']),
    );
  }

  /// Normaliza a entero. Devuelve `null` si el valor no es un número usable.
  ///
  /// Un `0` o un negativo se descartan: un build mínimo de cero no bloquearía
  /// a nadie y lo más probable es que sea un campo sin configurar.
  static int? _comoEntero(dynamic valor) {
    if (valor is int) {
      return valor > 0 ? valor : null;
    }
    if (valor is num) {
      final entero = valor.toInt();
      return entero > 0 ? entero : null;
    }
    if (valor is String) {
      final entero = int.tryParse(valor.trim());
      return (entero != null && entero > 0) ? entero : null;
    }
    return null;
  }

  /// Normaliza a texto; ausente o nulo se convierte en cadena vacía.
  static String _comoTexto(dynamic valor) {
    if (valor == null) {
      return '';
    }
    return valor.toString().trim();
  }

  /// Igual que [_comoTexto] pero deja `null` cuando no hay contenido, para
  /// distinguir "no configurado" de "configurado en vacío".
  static String? _comoTextoONulo(dynamic valor) {
    final texto = _comoTexto(valor);
    return texto.isEmpty ? null : texto;
  }

  /// Normaliza a booleano aceptando `true`, `1` y `"true"`/`"1"`.
  static bool _comoBooleano(dynamic valor) {
    if (valor is bool) {
      return valor;
    }
    if (valor is num) {
      return valor == 1;
    }
    if (valor is String) {
      final texto = valor.trim().toLowerCase();
      return texto == 'true' || texto == '1';
    }
    return false;
  }
}
