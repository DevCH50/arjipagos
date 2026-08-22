import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio de la política de versión de la app.
abstract class VersionRepository {
  /// Obtiene la política de versión mínima de la plataforma actual.
  Future<Resource<VersionApp>> getVersion();
}
