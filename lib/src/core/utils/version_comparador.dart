/// Comparación de versiones de la aplicación.
///
/// Funciones puras, sin dependencias de Flutter ni de la red, para que la
/// decisión de "hay que actualizar" sea trivialmente testeable. Quien las usa
/// es `VerificarActualizacionUseCase`.
library;

/// Compara dos nombres de versión estilo `1.0.24`.
///
/// Devuelve un número negativo si [a] es anterior a [b], `0` si son
/// equivalentes y positivo si [a] es posterior.
///
/// Es tolerante a propósito:
/// - Acepta distinto número de partes (`1.0` vs `1.0.24`), rellenando con ceros.
/// - Ignora sufijos no numéricos (`1.0.25-beta` cuenta como `1.0.25`), porque
///   una etiqueta de preproducción no debe alterar el orden frente al release.
/// - Una parte ilegible cuenta como `0` en lugar de lanzar una excepción: este
///   código corre en el arranque y nunca debe tumbar la app.
int compararSemver(String a, String b) {
  final partesA = _aNumeros(a);
  final partesB = _aNumeros(b);

  final total = partesA.length > partesB.length ? partesA.length : partesB.length;

  for (int i = 0; i < total; i++) {
    final valorA = i < partesA.length ? partesA[i] : 0;
    final valorB = i < partesB.length ? partesB[i] : 0;

    if (valorA != valorB) {
      return valorA < valorB ? -1 : 1;
    }
  }

  return 0;
}

/// Decide si la versión instalada quedó por debajo del umbral publicado.
///
/// [buildActual] es el build number instalado (el `+33` de `pubspec.yaml`) y
/// [versionActual] el nombre de versión (`1.0.24`).
///
/// El criterio principal es [buildUmbral]: un entero monotónico que las tiendas
/// obligan a incrementar en cada publicación, así que no admite empates ni
/// interpretaciones. Solo si el backend no lo manda se recurre a [versionUmbral].
///
/// Si no llega ninguno de los dos, devuelve `false`: sin umbral configurado no
/// se bloquea a nadie.
bool requiereActualizacion({
  required int buildActual,
  required String versionActual,
  int? buildUmbral,
  String? versionUmbral,
}) {
  if (buildUmbral != null && buildUmbral > 0) {
    return buildActual < buildUmbral;
  }

  if (versionUmbral != null && versionUmbral.trim().isNotEmpty) {
    return compararSemver(versionActual, versionUmbral) < 0;
  }

  return false;
}

/// Trocea un nombre de versión en su lista de números.
///
/// De cada parte se conservan solo los dígitos iniciales, de modo que
/// `25-beta`, `25+1` o `25rc` valen todos `25`.
List<int> _aNumeros(String version) {
  final limpia = version.trim();

  if (limpia.isEmpty) {
    return const [0];
  }

  return limpia.split('.').map((parte) {
    final digitos = RegExp(r'^\d+').firstMatch(parte.trim())?.group(0);
    return digitos == null ? 0 : (int.tryParse(digitos) ?? 0);
  }).toList();
}
