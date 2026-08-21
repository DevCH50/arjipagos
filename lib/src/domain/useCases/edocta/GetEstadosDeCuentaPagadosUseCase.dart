import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaPagadosRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener los pagos ya realizados.
///
/// Encapsula la consulta de los estados de cuenta pagados
/// de todos los alumnos desde el repositorio.
class GetEstadosDeCuentaPagadosUseCase {
  final EdoCtaPagadosRepository repository;

  GetEstadosDeCuentaPagadosUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con [EstadosDeCuentaResponse] o [Error].
  Future<Resource<EstadosDeCuentaResponse>> run() async {
    return await repository.getEstadosDeCuentaPagados();
  }
}
