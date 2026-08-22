import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/VersionService.dart';
import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/repository/VersionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de versión.
///
/// Delega la consulta al servicio HTTP [VersionService].
class VersionRepositoryImpl implements VersionRepository {
  final VersionService versionService;

  VersionRepositoryImpl(this.versionService);

  @override
  Future<Resource<VersionApp>> getVersion() async {
    try {
      return await versionService.getVersion();
    } catch (e) {
      // El mensaje que llega a la pantalla nunca es la excepción cruda.
      AppLogger.error('Error al obtener la versión: $e', tag: 'Version');
      return Error<VersionApp>(mensajeErrorRed(e));
    }
  }
}
