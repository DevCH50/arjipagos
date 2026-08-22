import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/constants/app_urls.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/version_comparador.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/repository/VersionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso que decide si hay que obligar a actualizar la app.
///
/// Compara la versión instalada (vía `PackageInfo`) contra la política que
/// publica el backend y devuelve un [ResultadoActualizacion] listo para pintar.
///
/// **Regla que gobierna todo el flujo:** ante cualquier duda —consulta que
/// falla, build que no se puede leer, política sin umbrales— se devuelve
/// [ResultadoActualizacion.sinCambios]. Dejar a un usuario fuera de la app por
/// un problema de red sería peor que permitirle usar una versión vieja.
class VerificarActualizacionUseCase {
  final VersionRepository repository;

  /// Lector del build instalado. Se inyecta para poder probarlo sin depender
  /// del canal nativo de `package_info_plus`.
  final Future<({int build, String version})> Function() leerVersionInstalada;

  VerificarActualizacionUseCase(
    this.repository, {
    required this.leerVersionInstalada,
  });

  /// Ejecuta la verificación.
  Future<ResultadoActualizacion> run() async {
    final resource = await repository.getVersion();

    if (resource is! Success<VersionApp>) {
      // El repositorio ya dejó el detalle en el log; aquí solo se decide
      // no molestar al usuario.
      return ResultadoActualizacion.sinCambios;
    }

    final VersionApp politica = resource.data;

    // El mantenimiento manda sobre cualquier comparación de versiones.
    if (politica.mantenimiento) {
      return ResultadoActualizacion(
        estado: EstadoActualizacion.mantenimiento,
        mensaje: politica.mensajeMantenimiento.isNotEmpty
            ? politica.mensajeMantenimiento
            : AppStrings.actualizacionMensajeMantenimiento,
      );
    }

    final ({int build, String version}) instalada;
    try {
      instalada = await leerVersionInstalada();
    } catch (e) {
      AppLogger.error('No se pudo leer la versión instalada: $e', tag: 'Version');
      return ResultadoActualizacion.sinCambios;
    }

    // Un build ilegible (0) invalidaría la comparación por entero: haría creer
    // que la app es más vieja que cualquier mínimo. En ese caso se ignora el
    // umbral numérico y se compara solo por nombre de versión.
    final int? buildInstalado = instalada.build > 0 ? instalada.build : null;

    final bool obligatoria = requiereActualizacion(
      buildActual: instalada.build,
      versionActual: instalada.version,
      buildUmbral: buildInstalado == null ? null : politica.buildMinimo,
      versionUmbral: politica.versionMinima,
    );

    if (obligatoria) {
      AppLogger.info(
        'Actualización obligatoria: instalada ${instalada.version}+'
        '${instalada.build}, mínima ${politica.versionMinima}+'
        '${politica.buildMinimo}',
        tag: 'Version',
      );
      return ResultadoActualizacion(
        estado: EstadoActualizacion.obligatoria,
        mensaje: politica.mensaje.isNotEmpty
            ? politica.mensaje
            : AppStrings.actualizacionMensajeObligatoria,
        urlTienda: _resolverUrlTienda(politica),
      );
    }

    final bool sugerida = requiereActualizacion(
      buildActual: instalada.build,
      versionActual: instalada.version,
      buildUmbral: buildInstalado == null ? null : politica.buildRecomendado,
      versionUmbral: politica.versionRecomendada,
    );

    if (sugerida) {
      return ResultadoActualizacion(
        estado: EstadoActualizacion.sugerida,
        mensaje: politica.mensaje.isNotEmpty
            ? politica.mensaje
            : AppStrings.actualizacionMensajeSugerida,
        urlTienda: _resolverUrlTienda(politica),
      );
    }

    return ResultadoActualizacion.sinCambios;
  }

  /// Elige el enlace de tienda: manda el del backend, y si no llegó se usa el
  /// respaldo compilado en la app.
  String _resolverUrlTienda(VersionApp politica) {
    if (politica.urlTienda.isNotEmpty) {
      return politica.urlTienda;
    }
    return Platform.isIOS ? AppUrls.tiendaIos : AppUrls.tiendaAndroid;
  }
}
