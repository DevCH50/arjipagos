import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener estados de cuenta sin pagar.
///
/// Encapsula la lógica de obtener los estados de cuenta
/// de todos los alumnos desde el repositorio.
class GetEstadosDeCuentaUseCase {
  final EdoCtaRepository repository;

  GetEstadosDeCuentaUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con [EstadosDeCuentaResponse] o [Error].
  Future<Resource<EstadosDeCuentaResponse>> run() async {
    return await repository.getEstadosDeCuenta();
  }
}
